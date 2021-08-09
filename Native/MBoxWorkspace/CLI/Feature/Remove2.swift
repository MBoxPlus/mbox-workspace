//
//  Remove.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/7/1.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit
import MBoxWorkspaceCore

extension MBCommander.Feature {
    open class Remove: Feature {

        open class override var description: String? {
            return "Remove a feature"
        }

        open class override var arguments: [Argument] {
            var arguments = super.arguments
            arguments << Argument("name", description: "Feature Name")
            return arguments
        }

        open override class var flags: [Flag] {
            var flags = [Flag]()
            flags << Flag("include-repo", description: "remove cached repo if the repo is not used by other features")
            flags << Flag("force", description: "Force remove the feature if there are unmerged commits")
            flags << Flag("all", description: "remove all feature, will not remove current feature and FreeMode")
            return flags + super.flags
        }

        open override class func autocompletion(argv: ArgumentParser) -> [String] {
            var completions = super.autocompletion(argv: argv)
            if let config = self.config {
                completions.append(contentsOf: config.features.values.map { $0.name })
            }
            return completions
        }

        open override func setup() throws {
            self.force = self.shiftFlag("force")
            self.all = self.shiftFlag("all")
            self.removeCache = self.shiftFlag("include-repo")
            try super.setup()
            self.name = self.shiftArgument("name")
        }

        public var name: String?
        public var all: Bool = false
        public var removeCache: Bool = false
        public var force: Bool = false

        open override func validate() throws {
            if !self.all && (self.name == nil || self.name == "" || self.name == "freemode") {
                try help("Need a feature name")
            }
            try super.validate()
        }

        open var removedFeatures: [MBConfig.Feature] = []

        open override func run() throws {
            try super.run()
            let features = try getFeatures()
            if !self.force {
                for feature in features {
                    try self.checkMerged(feature)
                }
            }
            self.removedFeatures = features
            let repos = getRemovedRepos(from: features)
            try remove(features: features, repos: repos)
            self.config.save()
            UI.log(info: "Remove Feature Success")
        }

        open func getFeatures() throws -> [MBConfig.Feature] {
            if self.all {
                return self.config.features.values.filter { (feature: MBConfig.Feature) -> Bool in
                    return !feature.free && !feature.isCurrent
                }
            } else {
                guard let feature = self.config.feature(withName: self.name!) else {
                    throw UserError("Could not find feature named `\(self.name!)`.")
                }
                if feature.free {
                    throw UserError("Could not remove Free Mode.")
                }
                if feature.isCurrent {
                    throw UserError("Could not remove current feature.")
                }
                return [feature]
            }
        }

        open func checkMerged(_ feature: MBConfig.Feature) throws {
            try UI.section("Check changes for Feature `\(feature)`") {
                for repo in feature.repos {
                    try UI.log(verbose: "[\(repo)]") {
                        guard let git = repo.originRepository?.git else { return }
                        try UI.log(verbose: "Check stash") {
                            if let stash = git.findStash(feature.stashName) {
                                throw UserError("[\(repo)] has uncommit changes in the stash: \(stash.1)")
                            }
                        }
                        try UI.log(verbose: "Check branch") {
                            let featureBranch = feature.branchName
                            if let branch = repo.lastBranch, branch != featureBranch {
                                UI.log(verbose: "Last branch is `\(branch)`, it is not the feature branch `\(featureBranch)`.")
                                return
                            }
                            guard git.exists(gitPointer: .branch(featureBranch), remote: false) else {
                                UI.log(verbose: "Feature branch not exists!")
                                return
                            }
                            guard let targetBranch = repo.targetBranch else { return }
                            for i in 0 ..< 2 {
                                if i == 1 {
                                    if git.url == nil {
                                        throw UserError("[\(repo)] has unmerged commit")
                                    }
                                    try git.fetch()
                                }
                                guard let targetTrackBranch = git.trackBranch(targetBranch) else { return }
                                if try self.checkMerged(git: git, featureBranch: featureBranch, targetBranch: targetTrackBranch) {
                                    UI.log(verbose: "Feature branch Merged!")
                                    return
                                }
                                guard let trackBranch = git.trackBranch(featureBranch) else {
                                    continue
                                }
                                if try self.checkMerged(git: git, featureBranch: featureBranch, targetBranch: trackBranch) {
                                    UI.log(verbose: "Feature branch Pushed!")
                                    return
                                }
                            }
                            throw UserError("[\(repo)] has unmerged commit")
                        }
                    }
                }
            }
        }

        open func checkMerged(git: GitHelper, featureBranch: String, targetBranch: String) throws -> Bool {
            let status = try git.checkMergeStatus(curBranch: targetBranch, target: .branch(featureBranch))
            return status != .diverged && status != .behind
        }

        open func getRemovedRepos(from features: [MBConfig.Feature]) -> [MBConfig.Repo] {
            if !self.removeCache {
                return []
            }
            var usedRepos = self.config.currentFeature.repos + self.config.freeFeature.repos
            usedRepos.removeDuplicates()
            var unusedRepos = [MBConfig.Repo]()
            for feature in features {
                unusedRepos.append(contentsOf: feature.repos.removeAll(usedRepos))
            }
            return unusedRepos
        }

        open func remove(features: [MBConfig.Feature], repos: [MBConfig.Repo]) throws {
            try UI.section("Remove Repo") {
                for repo in repos {
                    try UI.log(verbose: "Remove Repo [\(repo)]") {
                        if let r = repo.originRepository {
                            try r.remove()
                        } else {
                            UI.log(verbose: "[\(repo)] The repo `\(repo.storePath)` not exists.")
                        }
                    }
                }
            }
            for feature in features {
                try UI.section("Remove Feature `\(feature.name)`") {
                    try feature.cleanSupportFiles()
                    self.config.removeFeature(feature.name)
                    for repo in feature.repos where !repos.contains(repo) {
                        try UI.log(verbose: "[\(repo)]".ANSI(.yellow)) {
                            if let r = repo.originRepository {
                                try r.remove(with: repo)
                            } else {
                                UI.log(verbose: "[\(repo)] The repo `\(repo.storePath)` not exists.")
                            }
                        }
                    }
                }
            }
        }

        open override func setupHookCMD(_ cmd: MBCMD, preHook: Bool) {
            super.setupHookCMD(cmd, preHook: preHook)
            cmd.env["MBOX_REMOVED_FEATURES"] = self.removedFeatures.map { $0.name }.joined(separator: ",")
        }
    }
}

