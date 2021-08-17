//
//  Remove.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/6/19.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit
import MBoxWorkspaceCore

extension MBCommander {
    open class Remove: Repo {

        open class override var description: String? {
            return "Remove project from workspace"
        }

        open class override var arguments: [Argument] {
            var arguments = super.arguments
            arguments << Argument("name", description: "Repo Name", required: true, plural: true)
            return arguments
        }

        dynamic
        open override class var flags: [Flag] {
            var flags = [Flag]()
            flags << Flag("include-repo", description: "Remove repo from `.mbox/repos`")
            flags << Flag("force", description: "Force remove repo if modified")
            flags << Flag("all", description: "Remove all repos")
            return flags + super.flags
        }

        open override class func autocompletion(argv: ArgumentParser) -> [String] {
            var completions = super.autocompletion(argv: argv)
            if let config = self.config {
                completions.append(contentsOf: config.currentFeature.repos.map { $0.name })
            }
            return completions
        }

        dynamic
        open override func setup() throws {
            try super.setup()
            self.includeRepo = self.shiftFlag("include-repo")
            self.force = self.shiftFlag("force")
            self.all = self.shiftFlag("all")
            self.names = self.shiftArguments("name")
            self.showStatusAtFinish = true
        }

        open var names: [String] = []
        open var includeRepo = false
        open var force = false
        open var all = false

        open var repos = [MBConfig.Repo]()

        open override func validate() throws {
            if !self.all && self.names.isEmpty {
                try help("Require argument NAME, or use `--all` to remove all repos.")
            }
            try super.validate()
        }

        dynamic
        open func forceRemove(repo: MBWorkRepo?) -> Bool {
            return self.force
        }

        dynamic
        open func prepareRepos() throws {
            if self.all {
                self.repos = self.config.currentFeature.repos
            } else {
                for name in self.names {
                    try UI.log(verbose: "[\(name)]") {
                        var repos = config.currentFeature.findRepo(name: name, searchPackageName: false)
                        if repos.count == 0 {
                            repos = config.currentFeature.findRepo(name: name, searchPackageName: true)
                        }
                        if repos.count == 0 {
                            UI.log(warn: "Could not find the repo `\(name)`")
                            return
                        }
                        if repos.count > 1 {
                            throw UserError("Multiple repositories found: \(repos)")
                        }
                        let repo = repos.first!
                        UI.log(verbose: "The repo is `\(repo.name)`.")
                        self.repos << repo
                    }
                }
            }
            if self.repos.isEmpty {
                throw UserError("There is nothing to remove.")
            }
        }

        dynamic
        open override func run() throws {
            try super.run()
            try UI.section("Validate Repo") {
                try self.prepareRepos()
            }
            try UI.section("Remove Repo") {
                for repo in self.repos {
                    try UI.log(verbose: "[\(repo)]") {
                        try UI.log(verbose: "Remove from workspace" + (self.forceRemove(repo: repo.workRepository) ? " (Force)" : "")) {
                            try self.removeWorkspace(repo: repo)
                        }
                        if self.includeRepo,
                           let oriRepo = repo.originRepository {
                            try UI.log(verbose: "Remove origin repository: \(self.workspace.relativePath(oriRepo.path))") {
                                try oriRepo.remove()
                            }
                        }
                        try UI.log(verbose: "Remove from feature `\(self.config.currentFeature.name)`") {
                            try self.config.currentFeature.remove(repo: repo)
                        }
                    }
                }
            }

            self.config.save()
        }

        open func removeWorkspace(repo: MBConfig.Repo) throws {
            guard let workRepo = repo.workRepository else {
                return
            }
            try UI.log(verbose: "Check Changed Files") {
                try checkChangedFiles(workRepo)
            }
            try UI.log(verbose: "Check Unmerged Commits") {
                try checkUnmergedCommits(repo)
            }
            try UI.log(verbose: "Remove Work Directory") {
                try workRepo.remove()
            }
        }

        open func checkChangedFiles(_ repo: MBWorkRepo) throws {
            guard let git = repo.git else { return }
            if !self.forceRemove(repo: repo) {
                if git.isClean { return }
                throw UserError("`\(repo)` has changed files. If you want to remove it, please use below command:\n\tmbox remove \(repo) --force")
            }
            if self.includeRepo { return }
            try UI.log(verbose: "Reset git repo") {
                if git.isUnborn {
                    try git.clean()
                } else {
                    try git.reset(hard: true)
                }
            }
        }

        open func checkUnmergedCommits(_ repo: MBConfig.Repo) throws {
            if self.config.currentFeature.free { return }
            guard let workRepo = repo.workRepository else { return }
            if self.forceRemove(repo: workRepo) { return }
            guard let git = workRepo.git else { return }
            if git.isUnborn { return }
            if git.currentBranch == nil { return }
            if let otherBranch = git.trackBranch() {
                let status = try git.checkMergeStatus(target: .branch(otherBranch))
                if [GitHelper.MergeStatus.diverged, GitHelper.MergeStatus.behind].contains(status) {
                    throw UserError("[\(repo)] has some commits without be pushed. If you want to remove it, please use below command:\n\tmbox remove \(repo) --force")
                }
            } else if let otherGitPointer = repo.targetGitPointer ?? repo.baseGitPointer,
                otherGitPointer.isBranch,
                let otherBranch = git.trackBranch(otherGitPointer.value) {
                let status = try git.checkMergeStatus(target: .branch(otherBranch))
                if [GitHelper.MergeStatus.diverged, GitHelper.MergeStatus.forward].contains(status) {
                    throw UserError("[\(repo)] have some unmerged commits. If you want to remove it, please use below command:\n\tmbox remove \(repo) --force")
                }
            }
        }

        open override func setupHookCMD(_ cmd: MBCMD, preHook: Bool) {
            super.setupHookCMD(cmd, preHook: preHook)
            var values = [Any]()
            for repo in self.repos {
                let info = [
                    "name": repo.name,
                    "url": repo.url
                ]
                values.append(info)
            }
            cmd.env["MBOX_REMOVED_REPOS"] = values.toJSONString(pretty: false)
        }
    }
}
