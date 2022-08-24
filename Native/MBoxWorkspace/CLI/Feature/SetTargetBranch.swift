//
//  SetTargetBranch.swift
//  MBoxWorkspace
//
//  Created by 詹迟晶 on 2022/3/28.
//  Copyright © 2022 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBCommander.Feature {
    open class SetTargetBranch: Feature {
        open class override var description: String? {
            return "Set target branch for a/some repositories."
        }

        open override class var arguments: [Argument] {
            var args = super.arguments
            args.append(Argument("repo", description: "Repository Name"))
            args.append(Argument("target_branch", description: "Target Branch Name"))
            return args
        }

        open override class var options: [Option] {
            var options = super.options
            options.append(Option("json", description: "Configuration JSON String"))
            return options
        }

        open override class var flags: [Flag] {
            var flags = super.flags
            flags.append(Flag("all-repos", description: "Set target branch for all repositories"))
            return flags
        }

        open override func setup() throws {
            self.all = self.shiftFlag("all-repos")
            if let json: String = self.shiftOption("json") {
                guard let hash = json.toJSONDictionary() as? [String: String] else {
                    throw RuntimeError("Parse JSON Arugment Error!")
                }
                self.dict = hash
            } else if self.all {
                let branch: String = try self.shiftArgument("target_branch")
                for repo in self.config.currentFeature.repos {
                    self.dict[repo.name] = branch
                }
            } else {
                let name: String = try self.shiftArgument("repo")
                let branch: String = try self.shiftArgument("target_branch")
                self.dict = [name: branch]
            }
            try super.setup()
        }

        open override func validate() throws {
            try super.validate()
            if self.dict.isEmpty {
                throw UserError("No repo to update.")
            }
        }

        open var dict: [String: String] = [:]
        open var all = false

        open override func run() throws {
            try super.run()
            for (name, branch) in self.dict {
                guard let repo = self.config.currentFeature.findRepo(name: name, searchPackageName: false).first else {
                    throw UserError("Could not find repo named `\(name)`.")
                }
                try self.validate(repo: repo, branch: branch)
                try self.update(repo: repo, branch: branch)
            }
            self.config.save()
        }

        open func validate(repo: MBConfig.Repo, branch: String) throws {
            guard let git = repo.originRepository?.git else {
                throw RuntimeError("[\(repo)] Git has something wrong.")
            }
            if git.remoteBranch(named: branch) != nil { return }
            try git.fetch()
            if git.remoteBranch(named: branch) != nil { return }
            throw UserError("[\(repo)] The branch `\(branch)` not found.")
        }

        open func update(repo: MBConfig.Repo, branch: String) throws {
            UI.log(info: "[\(repo)] Update Target Branch: `\(branch)` (from `\(repo.targetBranch ?? "none")`)")
            repo.targetBranch = branch
        }
    }
}

