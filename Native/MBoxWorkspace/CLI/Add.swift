//
//  Add.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/6/4.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit
import MBoxWorkspaceCore

extension MBCommander {
    open class Add: Repo {

        open class override var description: String? {
            return "Add a repo into current feature"
        }

        open class override var arguments: [Argument] {
            var arguments = super.arguments
            arguments << Argument("name", description: "Repo Name/URL/Path", required: true)
            arguments << Argument("target_branch", description: "Merge to the target branch", required: false)
            arguments << Argument("base_branch", description: "Check from the base branch. Defaults same as TARGET_BRANCH", required: false)
            return arguments
        }

        dynamic
        open override class var options: [Option] {
            var options = [Option]()
            options << Option("mode", description: "Use `copy`/`move`/`worktree` to handle local path")
            return options + super.options
        }

        dynamic
        open override class var flags: [Flag] {
            var flags = [Flag]()
            flags << Flag("checkout-from-commit", description: "Checkout the feature branch from the commit instead of the latest base branch. It only works in a feature.")
            flags << Flag("recurse-submodules", description: "After the clone is created, initialize all submodules within, using their default settings.")
            flags << Flag("keep-local-changes", description: "Keep local changes when add a local repository with copy/move mode.")
            return flags + super.flags
        }
        
        dynamic
        open override func setup() throws {
            self.keepLocalChanges = self.shiftFlag("keep-local-changes", default: true)
            self.recurseSubmodules = self.shiftFlag("recurse-submodules")
            self.mode = MBRepo.Mode.mode(for: self.shiftOption("mode", default: "unknown"))
            self.checkoutFromCommit = self.shiftFlag("checkout-from-commit")
            if let name = self.shiftArgument("name") {
                if !name.contains("/") {
                    self.name = name
                } else if name.lowercased().hasPrefix("https://") || name.lowercased().hasPrefix("http://") || name.contains("@") {
                    self.url = name
                } else if name.hasPrefix("~/") {
                    self.path = name.expandingTildeInPath
                } else if name.isAbsolutePath {
                    self.path = name
                } else {
                    self.path = FileManager.pwd.appending(pathComponent: name)
                }
                if let path = self.path {
                    self.path = path.cleanPath
                }
            }
            if !self.config.currentFeature.free {
                self.targetBranch = self.shiftArgument("target_branch")
            }
            if let baseBranch = self.shiftArgument("base_branch") {
                if baseBranch.isEmpty {
                    // This is a hook, some tools pass the empty argument, we retry again
                    self.baseBranch = self.shiftArgument("base_branch")
                } else {
                    self.baseBranch = baseBranch
                }
            }
            self.showStatusAtFinish = true
            try super.setup()
        }

        open var name: String?
        open var path: String?
        open var url: String?
        open var baseBranch: String?
        open var targetBranch: String?
        open var mode: MBRepo.Mode = .unknown
        open var checkoutFromCommit: Bool?
        open var recurseSubmodules: Bool = false
        open var keepLocalChanges: Bool = true
        open var addedRepo: MBConfig.Repo?
        open var isFirstAdd: Bool?
        open var fetched: Bool = false
        open var pulled: Bool = false

        dynamic
        open var useBaseCommit: Bool {
            if self.baseBranch != nil { return false }
            if let v = self.checkoutFromCommit {
                return v
            }
            if self.config.currentFeature.free {
                return true
            }
            return MBSetting.merged.workspace.checkoutFromCommit
        }

        open var feature: MBConfig.Feature {
            return self.config.currentFeature
        }

        dynamic
        open override func validate() throws {
            if self.name == nil && self.url == nil && self.path == nil {
                try help("Add a project needs a `NAME` or a `URL` or a `PATH`.")
            }
            if let path = self.path {
                if !path.isDirectory {
                    try help("`\(path)` is NOT a directory.")
                }
                guard let _ = try? GitHelper(path: path) else {
                    try help("`\(path)` is NOT a git repo.")
                    return
                }
            }
            if self.config.currentFeature.free {
                if self.checkoutFromCommit == true && self.baseBranch != nil {
                    UI.log(verbose: "Ignore `BASE BRANCH` when have a flag `--checkout-from-commit`.")
                }
            }
            if let baseBranch = self.baseBranch, baseBranch.isEmpty {
                throw ArgumentError.invalidValue(value: "", argument: "BASE BRANCH")
            }
        }

        dynamic
        open override func run() throws {
            try super.run()
            var repo: MBConfig.Repo!
            try UI.section("Prepare Repository") {
                guard let v = try self.prepare() else {
                    throw UserError("Could not find a repo to add.")
                }
                repo = v
            }

            if repo.originRepository != nil, self.path != nil {
                self.analyzeHandleMode()
            }

            try UI.section("Setup Remote Repository") {
                try self.downloadRemoteRepository(repo)
            }

            // For Copy/Move, we use the branch in the local repository as our base branch
            var localGitPointer: GitPointer?
            if (self.mode == .copy || self.mode == .move),
               let path = self.path, path.isExists {
                localGitPointer = UI.section("Fetch current local branch") { () -> GitPointer? in
                    return try? repo.originRepository?.git?.currentDescribe()
                }
                if self.baseBranch == nil {
                    repo.baseGitPointer = localGitPointer
                }
            }

            try UI.section("Setup Git Reference") {
                try self.setupGitReference(repo)
            }

            if (self.mode == .copy || self.mode == .move), self.keepLocalChanges {
                UI.section("Check Keep Local Changes") {
                    if localGitPointer != repo.baseGitPointer {
                        self.keepLocalChanges = false
                        UI.log(verbose: "The base branch/commit is inconsistent with the local repository, will not keep local changes.")
                    }
                    if self.keepLocalChanges,
                       repo.originRepository?.git?.isClean == true {
                        self.keepLocalChanges = false
                        UI.log(verbose: "The local repository has not changes.")
                    }
                }
            }

            var currentRepo = config.currentFeature.findRepo(repo)
            currentRepo?.baseGitPointer = repo.baseGitPointer
            if currentRepo == nil {
                UI.section("Add `\(repo!)` into feature `\(config.currentFeature.name)`") {
                    currentRepo = self.config.currentFeature.add(repo: repo)
                    currentRepo?.lastGitPointer = repo.lastGitPointer
                }
            }

            if currentRepo?.path == nil {
                currentRepo?.path = repo.path
            }
            repo = currentRepo!
            self.addedRepo = repo

            if self.mode == .worktree {
                let targetPointer = try self.gitReferenceToCheckout(repo: repo)
                if targetPointer.isBranch {
                    try UI.section("Check Worktrees") {
                        do {
                            try self.validBranchToCheckout(repo: repo, branch: targetPointer.value)
                        } catch {
                            try? self.config.currentFeature.remove(repo: repo)
                            throw error
                        }
                    }
                }
            }

            if self.mode != .worktree {
                repo.path = repo.storePath
            }

            self.config.save()

            var importedLocalRepository = false
            if repo.originRepository == nil, let path = self.path {
                try UI.section("Import Local Repository") {
                    repo.path = path
                    try self.importLocalRepository(repo)
                    importedLocalRepository = true
                }
            }

            try UI.section("Preprocess Origin Repository") {
                try self.preprocessOriginRepository(repo)
                if repo.originRepository == nil {
                    throw RuntimeError("Repository invalid.")
                }
            }

            try UI.section("Setup Work Repository") {
                try self.setupWorkRepository(repo, localPath: self.path)
            }

            let target = try self.checkout(repo: repo)
            repo.lastGitPointer = nil
            repo.baseGitPointer = nil

            if let target = target, target.isBranch, !self.pulled {
                UI.section("Pull \(target)") {
                    guard let workRepo = repo.workRepository,
                          let git = workRepo.git,
                          let trackBranch = git.trackBranch(target.value) else {
                        UI.log(verbose: "No tracking branch. Skip pull.")
                        return
                    }
                    if git.currentCommit == (try? git.commit(for: .branch(trackBranch))) {
                        UI.log(verbose: "Already up to date. Skip pull.")
                        return
                    }
                    try? git.pull()
                }
            }

            if self.mode == .move,
               let path = self.path,
               path.isExists {
                if importedLocalRepository {
                    try? FileManager.default.removeItem(atPath: path)
                } else {
                    UI.log(warn: "The path `\(path)` not be removed. Please remove it manually.")
                }
            }

            UI.log(info: "Add repo `\(repo!)` success.")

            if config.currentFeature.free, let basePointer = repo.baseGitPointer, !basePointer.isBranch {
                UI.log(warn: "The repo `\(repo!)` is under the \(basePointer), not a branch.")
            }
        }

        dynamic
        open func searchRepo(by name: String) throws -> MBConfig.Repo? {
            if let repo = self.workspace.findAllRepo(name: name) {
                return .init(path: repo.path, feature: self.feature)
            }
            if let repo = self.config.features.values.flatMap(\.repos).first(where: { $0.isName(name) }) {
                let v = repo.copy() as! MBConfig.Repo
                v.targetGitPointer = nil
                v.baseGitPointer = nil
                v.feature = self.feature
                v._path = nil
                return v
            }
            return nil
        }

        open func validBranchToCheckout(repo: MBConfig.Repo, branch: String) throws {
            guard let git = repo.originRepository?.git else {
                throw RuntimeError("Git has something wrong.")
            }
            if git.currentBranch == branch {
                throw UserError("The branch `\(branch)` already checkout at `\(repo.path)`.")
            }
            let names = try git.listWorkTrees()
            for name in names {
                let head = try? git.HEAD(for: name)
                UI.log(verbose: "- \(name): \(head?.description ?? "Unknown")")
                if head == .branch(branch) {
                    let path = try? git.workTreePath(by: name)
                    throw UserError("The branch \(branch) already checkout at `\(path ?? "Unknown")`.")
                }
            }
        }

        dynamic
        open func fetchCommitToCheckout(repo: MBConfig.Repo) throws {

        }

        open func prepare() throws -> MBConfig.Repo? {
            try self.workspace.createStoreRepoDir()
            var repo: MBConfig.Repo? = nil
            if let name = self.name {
                repo = try self.searchRepo(by: name)
            }

            if let path = self.path {
                repo = MBConfig.Repo(path: path, feature: self.feature)
            }

            if let url = self.url {
                repo = MBConfig.Repo(url: url, feature: self.feature)
            }

            if let repo = repo,
               (repo.storePath.isSymlink && !FileManager.default.fileExists(atPath: repo.storePath)) {
                try FileManager.default.removeItem(atPath: repo.storePath)
            }
            return repo
        }

        open func analyzeHandleMode() {
            if self.mode != .unknown { return }
            guard let path = self.path else { return }
            let mode: String = UI.gets("How do you want to handle the `\(path)`?", items: ["Copy", "Move", "Worktree"])
            self.mode = MBRepo.Mode.mode(for: mode)
        }

        dynamic
        open func setupGitReference(_ repo: MBConfig.Repo) throws {
            if repo.baseGitPointer != nil {
                if config.currentFeature.free {
                    return
                } else if repo.targetGitPointer != nil {
                    return
                }
            }
            if !self.fetched {
                try repo.originRepository?.git?.fetch()
                self.fetched = true
            }
            if repo.baseGitPointer == nil {
                try self.analyzeBaseBranch(repo)
            }
            var message = "Setup repo `\(repo)`"
            if config.currentFeature.free {
                message.append(", based \(repo.baseGitPointer!)")
            } else {
                if repo.targetGitPointer == nil {
                    try self.analyzeTargetBranch(repo)
                }
                message.append(", [\(repo.baseGitPointer!)] -> [\(GitPointer.branch(repo.featureBranch!))] -> [\(repo.targetGitPointer!)]")
            }
            UI.log(info: message)
        }

        dynamic
        open func downloadRemoteRepository(_ repo: MBConfig.Repo) throws {
            self.isFirstAdd = repo.workRepository == nil

            if let originRepo = repo.originRepository {
                UI.log(verbose: "The repository is at `\(originRepo.path)`.")
            } else if repo.url != nil {
                try repo.clone(recurseSubmodules: self.recurseSubmodules)
                self.fetched = true
                self.pulled = true
            } else {
                UI.log(verbose: "Repo `\(repo)` missing.")
            }
        }

        dynamic
        open func importLocalRepository(_ repo: MBConfig.Repo) throws {
            try repo.import()
        }

        dynamic
        open func preprocessOriginRepository(_ repo: MBConfig.Repo) throws {

        }

        open func setupWorkRepository(_ repo: MBConfig.Repo, localPath: String?) throws {
            guard let originRepo = repo.originRepository else {
                throw RuntimeError("Invalid repository at `\(repo.path)`.")
            }
            guard let git = originRepo.git else {
                throw RuntimeError("[\(repo)] Git has something wrong.")
            }
            if git.isWorkTree == false && repo.workRepository?.git?.isWorkTree == false {
                if !originRepo.path.isSymlink || originRepo.path.destinationOfSymlink != repo.workRepository?.path {
                    throw UserError("[\(repo)] The paths cannot exist at the same time:\n\t- Cache: \(self.workspace.relativePath(repo.storePath))\n\t- Work:  \(self.workspace.relativePath(repo.workingPath))")
                }
            }
            try repo.work(repo.baseGitPointer, checkout: localPath == nil || !self.keepLocalChanges)
            if self.keepLocalChanges, let localPath = localPath {
                try UI.log(verbose: "Copy workcopy into `\(Workspace.relativePath(repo.workingPath))`") {
                    let cmd = RSyncCMD()
                    guard cmd.exec(sourceDir: localPath, targetDir: repo.workingPath, delete: false, ignoreExisting: false, progress: true, exclude: [".git"]) else {
                        throw RuntimeError("Copy workcopy failed!")
                    }
                }
                if self.mode == .move {
                    UI.log(verbose: "Copy workcopy into `\(Workspace.relativePath(repo.workingPath))`") {
                        try? FileManager.default.removeItem(atPath: localPath)
                    }
                }
            }
        }

        open func queryGitReference(repo: MBStoreRepo, message: String, onlyBranch: Bool = true, defaults: GitPointer?) throws -> GitPointer {
            guard let git = repo.git else {
                throw RuntimeError("[\(repo)] Git has something wrong: `\(repo.path)`")
            }
            var branches: [String] = []
            if onlyBranch {
                branches = git.remoteBranches
                branches = branches.map { name -> String in
                    guard let index = name.range(of: "/")?.upperBound else { return name }
                    return String(name[index...])
                }
                branches.append(contentsOf: repo.git?.localBranches ?? [])
            }

            if branches.count == 0 && onlyBranch {
                throw UserError("The branch list is empty.")
            } else if branches.count == 1 && onlyBranch {
                let branch = branches.first!
                UI.log(info: "Auto choice the branch `\(branch)`.".ANSI(.yellow))
                return .branch(branch)
            } else {
                var defaultValue: GitPointer? = nil
                if onlyBranch {
                    var defaultBranches = ["develop", "master"]
                    if let pointer = defaults, pointer.isBranch == true {
                        defaultBranches.insert(pointer.value, at: 0)
                    }
                    if let v = defaultBranches.filter(branches.contains).first {
                        defaultValue = .branch(v)
                    }
                } else {
                    defaultValue = defaults
                }

                while true {
                    var dvalue: (name: String, value: String)? = nil
                    if let defaultValue = defaultValue {
                        dvalue = (name: defaultValue.description, value: defaultValue.value)
                    }
                    let branch = UI.gets(message, default: dvalue)
                    if onlyBranch {
                        if branches.contains(branch) {
                            return .branch(branch)
                        } else {
                            UI.log(info: "The branch `\(branch)` does not exist.")
                        }
                    } else {
                        if let defaultValue = defaultValue, branch == defaultValue.value {
                            return defaultValue
                        }
                        if let v = git.reference(named: branch)?.ref {
                            return v
                        } else {
                            UI.log(info: "The reference `\(branch)` does not exist.")
                        }
                    }
                }
            }
        }
        
        dynamic
        open func isValided(_ repo: MBConfig.Repo) -> Bool  {
            return repo.originRepository != nil && repo.workRepository != nil
        }

        dynamic
        open func analyzeBaseBranch(_ repo: MBConfig.Repo) throws {
            guard let oriRepo = repo.originRepository else {
                throw RuntimeError()
            }
            if let branchName = repo.featureBranch,
               oriRepo.git?.exists(gitPointer: .branch(branchName)) == true {
                repo.baseGitPointer = .branch(branchName)
                UI.log(verbose: "The feature branch `\(branchName)` exists, will checkout it.")
                return
            }
            if self.useBaseCommit {
                if repo.baseGitPointer == nil {
                    try UI.log(verbose: "Query current version information due to \(self.config.currentFeature.free ? "FreeMode" : "`--checkout-from-commit`")") {
                        try self.fetchCommitToCheckout(repo: repo)
                    }
                }
                if repo.baseGitPointer == nil {
                    if let baseBranch = self.baseBranch {
                        if self.checkoutFromCommit == true {
                            UI.log(warn: "You set the flag `--checkout-from-commit`, but MBox could not find the commit and will checkout from the `\(baseBranch)`.")
                        }
                        repo.baseGitPointer = .unknown(baseBranch)
                    } else if self.checkoutFromCommit == true {
                        throw UserError("[\(repo)] Could not find the commit to checkout when the `--checkout-from-commit` set.\n\tRemove it and use `BASE BRANCH` to checkout from the branch.")
                    }
                }
            } else {
                if !self.feature.free, let baseGitPointer = repo.baseGitPointer {
                    UI.log(verbose: "Ignore the \(baseGitPointer) when without `--checkout-from-commit`.")
                    repo.baseGitPointer = nil
                }
                if let baseBranch = self.baseBranch {
                    repo.baseGitPointer = .unknown(baseBranch)
                }
            }

            if repo.baseGitPointer?.isUnknown == true {
                let baseRef = oriRepo.git?.reference(named: repo.baseBranch!)?.ref
                if baseRef == nil {
                    throw UserError("[\(repo)] Could not find the BASE reference `\(repo.baseBranch!)`.")
                }
                repo.baseGitPointer = baseRef
            }

            if let targetBranch = self.targetBranch {
                if oriRepo.git?.branch(named: targetBranch) == nil {
                    throw UserError("[\(repo)] Could not find the target branch `\(targetBranch)`.")
                }
                repo.targetBranch = targetBranch
            }
            repo.baseGitPointer ?= repo.targetGitPointer

            if repo.baseGitPointer == nil {
                let reference = try self.queryGitReference(repo: oriRepo, message: "Please enter BRANCH/TAG/COMMIT you want to checkout from:", onlyBranch: false, defaults: repo.lastGitPointer)
                repo.baseGitPointer = reference
            }

            if !config.currentFeature.free, repo.baseGitPointer == .branch(repo.featureBranch!) {
                throw UserError("The BASE reference `\(repo.baseGitPointer!)` could not be the same as feature branch.")
            }
        }

        dynamic
        open func analyzeTargetBranch(_ repo: MBConfig.Repo) throws {
            guard let featureBranch = repo.featureBranch else { return }
            repo.targetBranch = try self.targetBranch ?? self.queryGitReference(repo: repo.originRepository!, message: "Please enter BRANCH which the feature branch (\(featureBranch)) be merged into:", onlyBranch: true, defaults: repo.lastGitPointer).value
            if repo.targetBranch == featureBranch {
                throw UserError("The TARGET branch `\(repo.targetBranch!)` could not be the same as feature branch.")
            }
        }

        open func gitReferenceToCheckout(repo: MBConfig.Repo) throws -> GitPointer {
            if let featureBranch = repo.featureBranch {
                return .branch(featureBranch)
            } else if let basePointer = repo.baseGitPointer {
                return basePointer
            } else {
                throw RuntimeError("Invalid feature branch.")
            }
        }

        open func checkout(repo: MBConfig.Repo) throws -> GitPointer? {
            let targetPointer = try self.gitReferenceToCheckout(repo: repo)

            repo.lastGitPointer = nil

            let msg: String
            if let base = repo.baseGitPointer, base != targetPointer {
                msg = "Checkout \(targetPointer) based \(base)"
            } else {
                msg = "Checkout \(targetPointer)"
            }
            try UI.section(msg) {
                try repo.workRepository?.checkout(targetPointer, basePointer: repo.baseGitPointer, baseRemote: true, setUpStream: true)
            }
            return targetPointer
        }

        open override func setupHookCMD(_ cmd: MBCMD, preHook: Bool) {
            super.setupHookCMD(cmd, preHook: preHook)
            if let repo = self.addedRepo {
                cmd.env["MBOX_ADDED_NAME"] = repo.name
                cmd.env["MBOX_ADDED_PATH"] = repo.path
                cmd.env["MBOX_ADDED_URL"] = repo.url
                cmd.env["MBOX_ADDED_TYPE"] = try? repo.workRepository?.git?.currentDescribe().type
                cmd.env["MBOX_ADDED_REFERENCE"] = try? repo.workRepository?.git?.currentDescribe().value
            }
        }
    }
}
