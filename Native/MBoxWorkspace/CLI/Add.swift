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

        open override class var example: String? {
            return """
# Copy a relative path into current feature, and keep the local changes.
$ mbox add ../repo1 --mode copy --keep-local-changes

# Download a remote url into current feature
$ mbox add git@github.com:xx/xxx.git

# Download a repository with a name, the name maybe a component name or a repository name
$ mbox add AFNetworking
"""
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
            self.keepLocalChanges = self.shiftFlag("keep-local-changes", default: false)
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
            self.showStatusAtFinish = []
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
        open var keepLocalChanges: Bool = false
        open var addedRepo: MBConfig.Repo?
        open var isFirstAdd: Bool?
        open var fetched: Bool = false
        open var pulled: Bool = false

        open var isAddLocalRepo = false

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
            var repo: MBConfig.Repo = try UI.section("Prepare Repository") {
                guard let v = try self.prepare() else {
                    throw UserError("Could not find a repo to add.")
                }
                return v
            }
            repo.feature = self.feature

            if let path = self.path, path != repo.workingPath, repo.workingPath.isExists {
                throw UserError("[\(repo)] The work path exists: \(self.workspace.relativePath(repo.workingPath))")
            }

            try self.setupRepoName(repo)

            if repo.originRepository != nil, self.path != nil {
                self.isAddLocalRepo = true
                try self.analyzeHandleMode()
            }

            try UI.section("Setup Remote Repository") {
                try self.downloadRemoteRepository(repo)
            }

            var localGitPointer: GitPointer?
            if self.isAddLocalRepo {
                localGitPointer = UI.section("Fetch current local branch") { () -> GitPointer? in
                    return try? repo.originRepository?.git?.currentDescribe()
                }
            }

            if self.isAddLocalRepo,
               (self.mode == .copy || self.mode == .move),
               self.baseBranch == nil {
                // For Copy/Move, we use the branch in the local repository as our base branch
                repo.baseGitPointer = localGitPointer
            }

            try UI.section("Setup Git Reference") {
                try self.setupGitReference(repo)
            }

            if self.isAddLocalRepo,
               (self.mode == .copy || self.mode == .move),
               self.keepLocalChanges,
               let path = self.path, path != repo.workingPath {
                UI.section("Check Keep Local Changes") {
                    if localGitPointer != repo.baseGitPointer {
                        self.keepLocalChanges = false
                        UI.log(verbose: "The base branch/commit is inconsistent with the local repository, will not keep local changes.")
                    }
                }
            }

            if let currentRepo = config.currentFeature.findRepo(repo) {
                currentRepo.baseGitPointer = repo.baseGitPointer
                currentRepo.path = repo.path
                repo = currentRepo
            }

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

            var importedLocalRepository = false
            if repo.originRepository != nil, let path = self.path, self.mode != .worktree {
                try UI.section("Import Local Repository") {
                    if path == repo.workingPath {
                        let storePath = repo.storePath
                        let relativePath = path.relativePath(from: storePath.deletingLastPathComponent)
                        try UI.log(verbose: "Link `\(workspace.relativePath(storePath))` -> `\(relativePath)`") {
                            try FileManager.default.createSymbolicLink(atPath: storePath,
                                                                       withDestinationPath: relativePath)
                        }
                    } else {
                        repo.path = path
                        try self.importLocalRepository(repo)
                        importedLocalRepository = true
                    }
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
                repo.lastGitPointer = nil
                repo.baseGitPointer = nil
            }

            UI.section("Add `\(repo)` into feature `\(config.currentFeature.name)`") {
                self.config.currentFeature.add(repo: repo)
                self.config.save()
            }

            if !self.pulled,
               let workRepo = repo.workRepository,
               let git = workRepo.git {
                let curInfo = try git.currentDescribe()
                if curInfo.isBranch {
                    UI.section("Pull \(curInfo)") {
                        guard let trackBranch = git.trackBranch(curInfo.value) else {
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
            }

            if self.mode == .move,
               let path = self.path,
               path.isExists,
               path != repo.workingPath {
                if importedLocalRepository {
                    try? FileManager.default.removeItem(atPath: path)
                } else {
                    UI.log(warn: "The path `\(path)` not be removed. Please remove it manually.")
                }
            }

            UI.log(info: "Add repo `\(repo)` success.")

            if config.currentFeature.free, let basePointer = repo.baseGitPointer, !basePointer.isBranch {
                UI.log(warn: "The repo `\(repo)` is under the \(basePointer), not a branch.")
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
                if let storeRepo = self.workspace.findAllRepo(url: url) {
                    UI.log(verbose: "Reuse local path `\(storeRepo.path)` instead of the url `\(url)`.")
                    repo = MBConfig.Repo(path: storeRepo.path, feature: self.feature)
                } else {
                    repo = MBConfig.Repo(url: url, feature: self.feature)
                }
            }

            if let repo = repo,
               (repo.storePath.isSymlink && !FileManager.default.fileExists(atPath: repo.storePath)) {
                try FileManager.default.removeItem(atPath: repo.storePath)
            }
            return repo
        }

        open func analyzeHandleMode() throws {
            if self.mode != .unknown { return }
            guard let path = self.path else { return }
            if path.cleanPath.deletingLastPathComponent == self.workspace.rootPath {
                self.mode = .move
                return
            }
            let mode: String = try UI.gets("How do you want to handle the `\(path)`?", items: ["Copy", "Move", "Worktree"])
            self.mode = MBRepo.Mode.mode(for: mode)
        }

        open func setupRepoName(_ repo: MBConfig.Repo) throws {
            let names = self.feature.repos.map { $0.name.lowercased() }
            if names.contains(repo.name.lowercased()) {
                UI.log(verbose: "Repo name `\(repo.name)` already in used, use `\(repo.fullName)`.")
                repo.name = repo.fullName
            }
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
            try UI.log(verbose: "Check base reference:") {
                if repo.originRepository?.git?.pointer(for: repo.baseGitPointer!) == nil {
                    throw UserError("Could not find base \(repo.baseGitPointer!).")
                }
            }
            var message = "Setup repo `\(repo)`"
            if config.currentFeature.free {
                message.append(", based \(repo.baseGitPointer!)")
            } else {
                if repo.targetGitPointer == nil {
                    try self.analyzeTargetBranch(repo)
                }
                try UI.log(verbose: "Check target branch:") {
                    if repo.originRepository?.git?.pointer(for: repo.targetGitPointer!) == nil {
                        throw UserError("Could not find target \(repo.targetGitPointer!).")
                    }
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

        open func importLocalRepository(_ repo: MBConfig.Repo) throws {
            try repo.import()
        }

        dynamic
        open func preprocessOriginRepository(_ repo: MBConfig.Repo) throws {

        }

        open func setupWorkRepository(_ repo: MBConfig.Repo, localPath: String?) throws {
            if repo.workRepository == nil {
                try repo.work(useCache: localPath == nil || !self.keepLocalChanges, reset: false)
            } else {
                UI.log(verbose: "[\(repo)] The repository is working!")
            }

            let target = try self.gitReferenceToCheckout(repo: repo)

            if self.keepLocalChanges, let localPath = localPath {
                if let base = repo.baseGitPointer, base != target, target.isBranch {
                    try? repo.originRepository?.git?.createBranch(target.value, base: base)
                }
                try repo.workRepository?.git?.setHEAD(target)
                try UI.log(verbose: "Copy workcopy into `\(Workspace.relativePath(repo.workingPath))`") {
                    let cmd = RSyncCMD()
                    guard cmd.exec(sourceDir: localPath, targetDir: repo.workingPath, delete: false, progress: true, excludes: [".git"]) else {
                        throw RuntimeError("Copy workcopy failed!")
                    }
                }
            } else {
                let msg: String
                if let base = repo.baseGitPointer, base != target {
                    msg = "Checkout \(target) based \(base)"
                } else {
                    msg = "Checkout \(target)"
                }
                try UI.log(verbose: msg) {
                    try repo.workRepository?.checkout(target, basePointer: repo.baseGitPointer, baseRemote: true, setUpStream: true, force: true)
                }
            }
        }

        open func queryGitReference(repo: MBStoreRepo, message: String, onlyBranch: Bool = true, defaults: GitPointer?) throws -> GitPointer {
            guard let git = repo.git else {
                throw RuntimeError("[\(repo)] Git has something wrong: `\(repo.path)`")
            }
            var branches = Set<String>()
            branches = Set(git.remoteBranches)
            branches = Set(branches.map { name -> String in
                guard let index = name.range(of: "/")?.upperBound else { return name }
                return String(name[index...])
            })
            if let localBranches = repo.git?.localBranches {
                branches.formUnion(localBranches)
            }
            branches.remove("HEAD")

            if onlyBranch {
                if branches.count == 0 {
                    throw UserError("The branch list is empty.")
                } else if branches.count == 1 {
                    let branch = branches.first!
                    UI.log(info: "Auto choice the branch `\(branch)`.".ANSI(.yellow))
                    return .branch(branch)
                }
            }

            var defaultValue: String? = nil
            var defaultBranches = ["develop", "master"]
            if let defaults = defaults {
                if onlyBranch {
                    if defaults.isBranch == true {
                        defaultBranches.insert(defaults.value, at: 0)
                    }
                } else {
                    defaultBranches.insert(defaults.value, at: 0)
                }
            }
            if let v = defaultBranches.filter(branches.contains).first {
                defaultValue = v
            }

            var allItems = branches
            if !onlyBranch {
                try? allItems.formUnion(git.tags().keys)
            }

            while true {
                let value = try UI.gets(message, default: defaultValue) { input in
                    allItems.first { $0.hasPrefix(input) }
                }
                if onlyBranch {
                    if branches.contains(value) {
                        return .branch(value)
                    } else {
                        UI.log(info: "The branch `\(value)` does not exist.")
                    }
                } else {
                    if let defaults = defaults, defaults.value == value {
                        return defaults
                    }
                    if let v = git.reference(named: value)?.ref {
                        return v
                    } else {
                        UI.log(info: "The reference `\(value)` does not exist.")
                    }
                }
            }
        }
        
        dynamic
        open func isValided(_ repo: MBConfig.Repo) -> Bool  {
            return repo.originRepository != nil && repo.workRepository != nil
        }

        dynamic
        open func shouldFetchCommitToCheckout() -> Bool {
            if self.useBaseCommit, self.config.currentFeature.repos.count > 0 {
                return true
            }
            return false
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
            if self.shouldFetchCommitToCheckout() {
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
