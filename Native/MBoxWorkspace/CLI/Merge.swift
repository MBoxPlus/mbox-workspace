//
//  Merge.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/7/6.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBCommander {
    open class Merge: MBCommander {
        open class override var description: String? {
            return "Merge `other feature`/`target branch` into current feature"
        }

        open class override var arguments: [Argument] {
            var arguments = super.arguments
            arguments << Argument("name", description: "Merge the Feature into current feature")
            return arguments
        }

        open override class var options: [Option] {
            var options = super.options
            options << Option("repo", description: "Specify a repo, use this option multiple times to specify multiple repos.")
            options << Option("no-repo", description: "Exclude a repo, use this option multiple times to exclude multiple repos.")
            return options
        }

        dynamic
        open override class var flags: [Flag] {
            var flags = super.flags
            flags << Flag("dry-run", description: "Do everything except actually merge.")
            flags << Flag("fetch", description: "Do fetch before analyze. Defaults: True")
            return flags
        }

        dynamic
        open override func setup() throws {
            self.fetch = self.shiftFlag("fetch", default: true)
            self.dryRun = self.shiftFlag("dry-run")
            try super.setup()
            let repos: [String]? = self.shiftOptions("repo")
            self.name = self.shiftArgument("name")
            if self.name != nil {
                self.feature = self.config.feature(withName: name)
            } else {
                self.feature = self.config.currentFeature
            }
            if let feature = self.feature {
                if let repos = repos {
                    for name in repos {
                        let value = feature.findRepo(name: name)
                        if value.count == 0 {
                            throw UserError("Could not find the repo `\(name)` in the feature `\(feature.name)`")
                        }
                        if value.count > 1 {
                            throw UserError("Multiple repositories found by name `\(name)`: \(value)")
                        }
                        if self.feature != self.config.currentFeature,
                           self.config.currentFeature.findRepo(name: name).count == 0 {
                            throw UserError("Could not find the repo `\(name)` in the current feature `\(self.config.currentFeature.name)`")
                        }
                        self.repos.append(value.first!)
                    }
                } else {
                    self.repos = feature.repos
                }
            }
        }

        open var name: String?
        open var feature: MBConfig.Feature?
        open var repos: [MBConfig.Repo] = []
        open var dryRun: Bool = false
        open var fetch: Bool = true

        open override func validate() throws {
            if self.feature == nil {
                throw UserError("Could not find the feature which named `\(self.name!)`.")
            }
            if self.repos.isEmpty {
                throw UserError("No any repos to merge.")
            }
            try super.validate()
        }

        open override func run() throws {
            try super.run()
            try self.prepare()
            try self.performMerge()
        }

        dynamic
        open func prepare() throws {
            if self.feature == self.config.currentFeature {
                UI.log(verbose: "Merge target branch for current feature `\(self.feature!.name)`")
            } else {
                UI.log(info: "Merge feature \(self.feature!.name) into \(self.config.currentFeature.name)")
            }
        }

        open func performMerge() throws {
            var errors = [Error]()
            var data = [String: [String: Any]]()
            for repo in repos {
                try UI.section("[\(repo)]") {
                    do {
                        defer {
                            repo.workRepository?.git?.unlock()
                        }
                        repo.workRepository?.git?.lock()
                        if let info = try self.performMerge(repo: repo) {
                            data[repo.name] = info
                        }
                        if !self.dryRun {
                            UI.log(info: "Merge Done!")
                        }
                    } catch {
                        if self.throwErrorWhenMergeFailed(repo, error: error) {
                            throw error
                        } else {
                            errors.append(error)
                        }
                        UI.log(error: error.localizedDescription)
                        if !self.dryRun {
                            UI.log(info: "Merge Failed!")
                        }
                    }
                }
            }
            if !errors.isEmpty {
                UI.statusCode = 1
            } else if MBProcess.shared.apiFormatter != .none {
                UI.log(api: data)
            }
        }

        dynamic
        open func throwErrorWhenMergeFailed(_ repo: MBConfig.Repo, error: Error) -> Bool {
            return false
        }

        dynamic
        open func performMerge(repo: MBConfig.Repo) throws -> [String: Any]? {
            guard let workRepo = repo.workRepository else {
                UI.log(warn: "[\(repo)] The repo is not in work, you should run `mbox add \(repo)` to add it.")
                return nil
            }
            guard let git = workRepo.git else {
                UI.log(warn: "[\(repo)] The git has something wrong.")
                return nil
            }

            let current = try git.currentDescribe()
            if !current.isBranch {
                UI.log(warn: "[\(workRepo)] is in \(current), It is not a branch. Skip it.")
                return nil
            }

            if !self.config.currentFeature.free,
               let curRepo = self.config.currentFeature.findRepo(repo),
               let branchName = curRepo.featureBranch,
               branchName != current.value {
                UI.log(warn: "[\(repo)] is not in feature branch `\(branchName)`. Skip it.")
                return nil
            }

            if self.fetch {
                try self.fetch(repo: workRepo)
            }

            guard let source = try sourceBranch(repo: repo, feature: feature!) else {
                UI.log(warn: "[\(repo)] There is not branch/commit to merge. Skip it.")
                return nil
            }
            var tagDesc = ""
            if source.isCommit,
                let tag = try? git.tag(for: source.value) {
                    tagDesc = " (tag `\(tag)`)"
            }
            UI.log(info: "Merge \(source)\(tagDesc) into \(current).".ANSI(.green))

            let status = try self.checkMerge(repo: workRepo, current: current.value, other: source)
            if status == .uptodate || status == .forward {
                UI.log(info: "There is nothing to merge.")
                return ["source": source.value,
                        "source_type": source.type,
                        "current": current.value,
                        "ready": true,
                        "type": "git-merge"]
            }

            if !self.dryRun {
                do {
                    let stashName = "[MBox] Merge \(source) into \(current)"
                    let stash = try self.stash(repo: workRepo, name: stashName)
                    defer {
                        if let stash = stash {
                            do {
                                try self.unstash(repo: workRepo, stash: stash)
                            } catch {
                                UI.log(error: "[\(workRepo)] Apply Stash failed: \(error.localizedDescription)")
                            }
                        }
                    }
                    try self.merge(repo: workRepo, target: source)
                }

                self.checkConflicts(repo: workRepo)
            }

            return ["source": source.value,
                    "source_type": source.type,
                    "current": current.value,
                    "ready": false,
                    "type": "git-merge"]
        }

        dynamic
        open func sourceBranch(repo: MBConfig.Repo, feature: MBConfig.Feature, source: GitPointer? = nil) throws -> GitPointer? {
            var pointer = source
            if pointer == nil {
                if feature == self.config.currentFeature {
                    pointer = repo.targetGitPointer
                } else {
                    pointer = repo.lastGitPointer
                }
            }
            guard let source = pointer else {
                return nil
            }
            guard source.isBranch else {
                return source
            }
            if let remote = repo.workRepository?.git!.trackBranch(source.value) {
                return .branch(remote)
            }
            if let remote = repo.workRepository?.git!.remoteBranch(named: source.value)?.name {
                return .branch(remote)
            }
            return source
        }

        open func fetch(repo: MBWorkRepo) throws {
            try repo.git?.fetch()
        }

        open func stash(repo: MBWorkRepo, name: String) throws -> Stash? {
            return try repo.git?.save(stash: name, untracked: true)
        }

        open func unstash(repo: MBWorkRepo, stash: Stash) throws {
            try repo.git?.apply(stash: stash.message, drop: true)
        }

        open func checkMerge(repo: MBWorkRepo, current: String, other: GitPointer) throws -> GitHelper.MergeStatus {
            return try repo.git!.checkMergeStatus(curBranch: current, target: other)
        }

        open func merge(repo: MBWorkRepo, target: GitPointer) throws {
            try repo.git!.merge(with: target)
        }

        open func checkConflicts(repo: MBWorkRepo) {
            if repo.git!.hasConflicts {
                UI.log(warn: "There are some conflict files in repo `\(repo)`")
                UI.statusCode = 1
            }
        }
    }
}
