//
//  Start.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/6/17.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit
import MBoxWorkspaceCore

extension MBCommander.Feature {
    open class Start: Feature {

        open class override var description: String? {
            return "Create a new feature, or continue a exist feature"
        }

        open class override var arguments: [Argument] {
            var arguments = super.arguments
            arguments << Argument("name", description: "Feature Name", required: true)
            return arguments
        }

        dynamic
        open override class var options: [Option] {
            var options = [Option]()
            options << Option("prefix", description: "Create a new feature with a custom branch prefix. Default is `feature/`, use `--prefix=` to disable it.")
            options << Option("repos", description: "Create a new feature with a custom repo list. It is a JSON String, eg: {\"Aweme\": \"develop\"} or {\"Aweme\": {\"base\": \"0ABCD\", \"base_type\": \"commit\", \"target_branch\": \"develop\"}}")
            return options + super.options
        }

        dynamic
        open override class var flags: [Flag] {
            var flags = [Flag]()
            flags << Flag("clear", description: "Create a new feature with a empty workspace")
            flags << Flag("checkout-from-remote", description: "Create a new feature branch from remote base branch, it will fetch remote. Defaults is true if current is in a feature.")
            flags << Flag("keep-changes", description: "Create a new feature with local changes")
            flags << Flag("pull", description: "Pull remote branch after finish")
            flags << Flag("recurse-submodules", description: "After the clone is created, initialize all submodules within, using their default settings.")
            return flags + super.flags
        }

        open override class func autocompletion(argv: ArgumentParser) -> [String] {
            var completions = super.autocompletion(argv: argv)
            if let config = self.config {
                completions.append(contentsOf: config.features.values.map { $0.name })
            }
            return completions
        }

        dynamic
        open override func setup() throws {
            self.recurseSubmodules = self.shiftFlag("recurse-submodules")
            self.clear = self.shiftFlag("clear")
            self.keep = self.shiftFlag("keep-changes")
            self.checkoutRemote = self.shiftFlag("checkout-from-remote", default: !self.config.currentFeature.free)
            self.prefix = self.shiftOption("prefix")
            self.pull = self.shiftFlag("pull")
            self.reposJSON = self.shiftOption("repos")
            self.name = try self.shiftArgument("name", default: "")
            self.showStatusAtFinish = true
            try super.setup()
        }

        public var name: String = ""
        public var clear: Bool = false
        public var keep: Bool? = nil
        public var prefix: String?
        public var pull: Bool = false
        public var recurseSubmodules: Bool = false
        public var checkoutRemote: Bool = false
        public var reposJSON: String?
        public var repos: [MBConfig.Repo] = []

        public var isCreate: Bool = false

        open func copyRepos(_ repos: [String: String]) throws -> (repos: [MBConfig.Repo], unfound: [String]) {
            var unfound = [String]()
            var found = [MBConfig.Repo]()
            for (name, branch) in repos {
                guard let repo = self.config.currentFeature.findRepo(name: name).first else {
                    unfound.append(name)
                    continue
                }
                found << MBConfig.Repo.copy(with: repo, baseGitPointer: .branch(branch), targetBranch: branch)
            }
            return (repos: found, unfound: unfound)
        }

        open func copyRepos(_ repos: [String: [String: String]]) throws -> (repos: [MBConfig.Repo], unfound: [String]) {
            var unfound = [String]()
            var found = [MBConfig.Repo]()
            for (name, info) in repos {
                guard let repo = self.config.currentFeature.findRepo(name: name).first else {
                    unfound.append(name)
                    continue
                }
                guard let base = info["base"] else {
                    throw UserError("Missing `base` key in the json.")
                }
                let baseGit: GitPointer
                if let baseType = info["base_type"] {
                    guard let g = GitPointer(type: baseType, value: base) else {
                        throw UserError("Unknown git type: \(baseType)")
                    }
                    baseGit = g
                } else {
                    baseGit = .unknown(base)
                }
                let targetBranch = info["target_branch"]
                found << MBConfig.Repo.copy(with: repo, baseGitPointer: baseGit, targetBranch: targetBranch ?? baseGit.value)
            }
            return (repos: found, unfound: unfound)
        }

        open func copyReposFromCurrentFeature() throws -> [MBConfig.Repo] {
            if self.clear { return [] }
            return try self.config.currentFeature.repos.map { repo in
                if self.config.currentFeature.free {
                    guard let git = repo.workRepository?.git else {
                        throw RuntimeError("Repo `\(repo)` is not a git repository.")
                    }
                    let curPointer = try git.currentDescribe()
                    if !curPointer.isBranch {
                        throw UserError("Repo `\(repo)` is not in a branch (\(curPointer)), please checkout a branch first.")
                    }
                    return MBConfig.Repo.copy(with: repo,
                                       baseGitPointer: curPointer,
                                       targetBranch: curPointer.value)
                } else {
                    return MBConfig.Repo.copy(with: repo,
                                       baseGitPointer: repo.baseGitPointer,
                                       targetBranch: repo.targetBranch ?? repo.baseBranch)
                }
            }
        }

        open func copyRepos() throws -> [MBConfig.Repo] {
            guard let json = self.reposJSON else {
                return try copyReposFromCurrentFeature()
            }
            var v: (repos: [MBConfig.Repo], unfound: [String])!
            let dict = json.toJSONDictionary()
            if let repoJSON = dict as? [String: String] {
                v = try copyRepos(repoJSON)
            } else if let repoJSON = dict as? [String: [String: String]] {
                v = try copyRepos(repoJSON)
            } else {
                throw ArgumentError.invalidValue(value: json, argument: "repos")
            }
            if !v.unfound.isEmpty {
                throw UserError("The repos are not found in current feature: \(v.unfound.joined(separator: ", "))")
            }
            return v.repos
        }

        open override func validate() throws {
            if self.name.count > 0 && (self.name !~ "^[^\\/](.*[^\\/])?$") {
                try self.help("The feature name `\(name)` is invalid!")
            }
            if self.clear && self.reposJSON != nil {
                throw ArgumentError.conflict("`--clear` and `--repos` could NOT used at same time.")
            }
            try UI.log(verbose: "Check git status") {
                try self.workspace.eachWorkRepos { repo in
                    guard let git = repo.git else {
                        throw RuntimeError("[\(repo)] has something wrong.")
                    }
                    if git.hasConflicts == true {
                        throw UserError("[\(repo)] has conflict files. Please resolve the conflict first.")
                    }
                }
            }
            try super.validate()
        }

        open var oldFeature: MBConfig.Feature!
        open var newFeature: MBConfig.Feature!

        dynamic
        open override func run() throws {
            try super.run()

            let newFeature = try getNewFeature(for: self.name, branchPrefix: self.prefix)
            self.newFeature = newFeature
            self.isCreate = newFeature.isNew == true

            oldFeature = self.config.currentFeature
            if newFeature.name != oldFeature.name {
                try self.switchFeature(newFeature, from: oldFeature, isCreate: isCreate)
            } else {
                UI.log(info: "MBox is in the feature `\(newFeature.name)`. Only try to restore repos.")
            }

            try self.applyFeature(newFeature, oldFeature: oldFeature, isCreate: isCreate)

            if self.pull {
                try UI.section("Pull repos") {
                    try self.pullRepos(feature: newFeature)
                }
            }
        }

        dynamic
        open func switchFeature(_ newFeature: MBConfig.Feature, from oldFeature: MBConfig.Feature, isCreate: Bool) throws {
            // Free Mode 切换到其他 Feature 需要保存当前分支名
            try UI.section("Save current git HEAD") {
                try self.saveGitStatus(feature: oldFeature)
            }

            // 缓存原 feature
            try UI.section("Stash previous feature `\(oldFeature.name)`") {
                oldFeature.regenerateStashHash()
                try self.saveStash(feature: oldFeature)
            }

            // 存储支持文件
            let keepSupportFiles = !self.clear && isCreate
            try UI.section("Backup support files for feature `\(oldFeature.name)` (Mode: \(keepSupportFiles ? "Keep": "Clear"))") {
                try self.saveSupportFiles(feature: oldFeature, keep: keepSupportFiles)
            }

            config.currentFeatureName = newFeature.name
            newFeature.isNew = nil
            config.save()
        }

        dynamic
        open func applyFeature(_ newFeature: MBConfig.Feature, oldFeature: MBConfig.Feature, isCreate: Bool) throws {
            // 还原项目列表
            try UI.section("Check repo exists") {
                try self.applyRepos(newFeature, isCreate: isCreate)
            }

            // 更新工作空间项目
            try UI.section("Update workspace") {
                try self.updateWorkspace(newFeature: newFeature, oldFeature: oldFeature)
            }

            // 切换 feature
            try UI.section("Checkout feature `\(newFeature.name)`") {
                try self.checkout(feature: newFeature)
            }

            // 还原上次的 stash
            if !isCreate {
                try UI.section("Restore feature `\(newFeature.name)`") {
                    try self.applyStash(feature: newFeature)
                }
            }

            // 还原支持文件
            if !isCreate {
                try UI.section("Restore support files") {
                    try self.applySupportFiles(feature: newFeature)
                }
            }

            if keep != false {
                if (oldFeature.free && isCreate) || keep == true {
                    // 1. 使用 --keep-changes 命令时，
                    // 2. 从 FreeMode 创建新 Feature 时，
                    // 将 oldFeature 的 stash 内容 apply 到新 Feature
                    try UI.section("Pick stash from `\(oldFeature.name)` into new feature `\(newFeature.name)`") {
                        try self.pickStash(into: newFeature, from: oldFeature)
                    }
                }
            }
        }

        open func getNewFeature(for name: String, branchPrefix: String?) throws -> MBConfig.Feature {
            if let feature = self.config.feature(withName: name) {
                UI.section("Switch to a exists feature `\(feature.name)`") {
                    if self.reposJSON != nil {
                        UI.log(warn: "Ignore `--repos` flags, because of the feature exists!")
                    }
                    if self.clear {
                        UI.log(warn: "Ignore `--clear` flags, because of the feature exists!")
                    }
                }
                return feature
            } else {
                let feature = try UI.section("Create a new feature `\(name)`") {
                    return try self.createNewFeature(for: name, branchPrefix: branchPrefix)
                }
                self.config.addFeature(feature)
                return feature
            }
        }

        dynamic
        open func createNewFeature(for name: String, branchPrefix: String?) throws -> MBConfig.Feature {
            self.repos = try self.copyRepos()
            let feature = self.config.currentFeature.copy(with: name, branchPrefix: branchPrefix)
            feature.repos = self.repos
            if feature.free {
                return feature
            }
            for repo in feature.repos {
                let branch = repo.featureBranch!
                if repo.baseGitPointer == .branch(branch) {
                    throw UserError("Could not checkout from \(repo.baseGitPointer!), it is same as the feature branch.")
                }
                if repo.targetBranch == branch {
                    throw UserError("Could not merge into the branch `\(repo.targetBranch!)`, it is same as the feature branch.")
                }
            }
            return feature
        }

        open func saveStash(feature: MBConfig.Feature) throws {
            try feature.eachRepos { repo in
                guard let git = repo.workRepository?.git else { return }
                try git.eachRepository { (name, git) -> Bool in
                    if name.isEmpty {
                        try git.save(stash: feature.stashName, untracked: true)
                    } else {
                        try UI.log(verbose: "[\(name)]") {
                            try git.save(stash: feature.stashName, untracked: true)
                        }
                    }
                    return true
                }
            }
        }

        open func saveGitStatus(feature: MBConfig.Feature) throws {
            try feature.eachRepos(block: { repo in
                guard let git = repo.workRepository?.git else { return }
                let curPointer = try git.currentDescribe()
                repo.lastGitPointer = curPointer
                if feature.free {
                    repo.baseGitPointer = nil
                }
            })
        }

        open func saveSupportFiles(feature: MBConfig.Feature, keep: Bool) throws {
            try feature.backupSupportFiles(removeSourceFiles: !keep)
        }

        open func copyRepos(to: MBConfig.Feature, from: MBConfig.Feature) throws {
            for repo in from.repos {
                UI.log(verbose: "- \(repo)") {
                    to.add(repo: repo)
                }
            }
        }

        open func applyRepos(_ feature: MBConfig.Feature, isCreate: Bool) throws {
            try feature.eachRepos(skipNonExists: false) { repo in
                try self.applyRepo(repo, requireUpdate: self.isCreate && self.checkoutRemote)
            }
        }

        dynamic
        open func applyRepo(_ repo: MBConfig.Repo, requireUpdate: Bool) throws {
            if let oriRepo = repo.originRepository {
                UI.log(verbose: "The repo has been downloaded.")
                if requireUpdate {
                    try oriRepo.git?.fetch()
                }
            } else {
                try UI.log(verbose: "The repo is missing, try to download.") {
                    try repo.clone(recurseSubmodules: self.recurseSubmodules)
                }
            }
            guard let git = repo.originRepository?.git else {
                throw RuntimeError("The repo is missing.")
            }
            var changed = false
            if repo.baseBranch != nil, let gitPointer = repo.baseGitPointer {
                guard let realPointer = git.reference(named: gitPointer.value)?.ref else {
                    throw UserError("[\(repo)] Could not find the base \(gitPointer).")
                }
                if gitPointer != realPointer || gitPointer.isUnknown {
                    UI.log(verbose: "Change base \(gitPointer) -> \(realPointer)")
                    repo.baseGitPointer = realPointer
                    changed = true
                }
            }
            if let gitPointer = repo.lastGitPointer {
                guard let realPointer = git.reference(named: gitPointer.value)?.ref else {
                    throw UserError("[\(repo)] Could not find the last \(gitPointer).")
                }
                if gitPointer != realPointer || gitPointer.isUnknown {
                    UI.log(verbose: "Change last \(gitPointer) -> \(realPointer)")
                    repo.lastGitPointer = realPointer
                    changed = true
                }
            }
            if let gitPointer = repo.targetGitPointer {
                guard let realPointer = git.reference(named: gitPointer.value)?.ref else {
                    throw UserError("[\(repo)] Could not find the target \(gitPointer).")
                }
                if gitPointer != realPointer || gitPointer.isUnknown {
                    UI.log(verbose: "Change target \(gitPointer) -> \(realPointer)")
                    repo.targetGitPointer = realPointer
                    changed = true
                }
            }
            if changed {
                self.config.save()
            }
        }

        open func checkout(feature: MBConfig.Feature) throws {
            try feature.eachRepos(block: { repo in
                guard let git = repo.workRepository?.git else {
                    UI.log(error: "[\(repo)] The git has something wrong.")
                    return
                }
                if !git.isClean {
                    try UI.log(verbose: "There are unexpect uncommit changes, save stash!") {
                        try git.save(stash: "[MBox] Unexpect uncommit changes", untracked: true)
                    }
                }
                var target: GitPointer? = nil
                if let lastGitPointer = repo.lastGitPointer {
                    target = lastGitPointer
                }
                if target == nil, let featureBranch = repo.featureBranch {
                    target = .branch(featureBranch)
                }
                if target == nil, let basePointer = repo.baseGitPointer {
                    target = basePointer
                }
                if let targetPointer = target {
                    do {
                        try repo.workRepository?.checkout(targetPointer, basePointer: repo.baseGitPointer, baseRemote: self.checkoutRemote)
                    } catch {
                        UI.log(error: "[\(repo)] \(error.localizedDescription)")
                    }
                } else if !self.config.currentFeature.free {
                    UI.log(error: "[\(repo)] Could not get the feature branch.")
                }
            })
        }

        open func applyStash(feature: MBConfig.Feature) throws {
            try feature.eachRepos { repo in
                guard let git = repo.workRepository?.git else { return }
                try git.eachRepository { (name, git) -> Bool in
                    do {
                        if name.isEmpty {
                            try git.apply(stash: feature.stashName, drop: true)
                        } else {
                            try UI.log(verbose: "[\(name)]") {
                                try git.apply(stash: feature.stashName, drop: true)
                            }
                        }
                    } catch {
                        let fullName = name.isEmpty ? repo.name : "\(repo.name)/\(name)"
                        UI.log(error: "[\(fullName)] Apply stash failed, you could re-apply the stash `\(feature.stashName)`:\n\t\(error.localizedDescription)")
                    }
                    return true
                }
            }
        }

        open func updateWorkspace(newFeature: MBConfig.Feature, oldFeature: MBConfig.Feature) throws {
            let newNames = newFeature.repos.map { $0.name.lowercased() }
            let unusedRepos = oldFeature.repos.filter { !newNames.contains($0.name.lowercased()) }
            if !unusedRepos.isEmpty {
                try UI.log(verbose: "Remove old repos") {
                    try unusedRepos.forEach { repo in
                        try UI.log(verbose: "[\(repo)]") {
                            if repo.workRepository?.git?.isClean == false {
                                UI.log(error: "[\(repo)] The git status is not clean.")
                            } else {
                                try repo.workRepository?.cache()
                            }
                        }
                    }
                }
            }

            let addedRepos = newFeature.repos.filter { $0.workRepository == nil }
            if !addedRepos.isEmpty {
                try UI.log(verbose: "Work new repos") {
                    try addedRepos.forEach { repo in
                        try UI.log(verbose: "[\(repo)]") {
                            try repo.work()
                        }
                    }
                }
            }
        }

        open func applySupportFiles(feature: MBConfig.Feature) throws {
            try feature.restoreSupportFiles()
        }

        open func pickStash(into: MBConfig.Feature, from: MBConfig.Feature) throws {
            into.eachRepos(block: { repo in
                do {
                    try repo.workRepository?.git?.apply(stash: from.stashName, drop: true)
                } catch {
                    UI.log(error: "[\(repo.name)] Apply stash failed, you could re-apply the stash `\(from.stashName)`:\n\t\(error.localizedDescription)")
                }
            })
        }

        dynamic
        open func pullRepo(_ repo: MBConfig.Repo) throws {
            let git = repo.workRepository!.git!
            try git.pull()
        }

        open func pullRepos(feature: MBConfig.Feature) throws {
            feature.eachRepos { repo in
                guard let git = repo.workRepository?.git, let current = try? git.currentDescribe() else {
                    UI.log(verbose: "Repo `\(repo)` has something wrong.")
                    return
                }
                if !current.isBranch {
                    UI.log(verbose: "Repo `\(repo)` is in \(current), skip pull.")
                } else {
                    do {
                        try self.pullRepo(repo)
                    } catch {
                        UI.log(warn: "[\(repo)] Could not pull from remote: \(error.localizedDescription)")
                    }
                }
            }
        }

        open override func setupHookCMD(_ cmd: MBCMD, preHook: Bool) {
            super.setupHookCMD(cmd, preHook: preHook)
            cmd.env["MBOX_OLD_FEATURE"] = self.oldFeature.name
        }
    }
}

