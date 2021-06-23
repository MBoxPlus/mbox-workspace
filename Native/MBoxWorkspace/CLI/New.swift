//
//  New.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/7/12.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit
import MBoxWorkspaceCore

extension MBCommander {
    open class New: Repo {
        open class override var description: String? {
            return "Create a project in workspace"
        }

        open class override var arguments: [Argument] {
            var arguments = super.arguments
            arguments << Argument("name", description: "Project Name", required: true)
            arguments << Argument("branch", description: "Create the branch")
            return arguments
        }

        open override func setup(argv: ArgumentParser) throws {
            try super.setup(argv: argv)
            self.name = try self.shiftArgument("name")
            self.branch = try self.shiftArgument("branch", default: self.branch)
            self.showStatusAtFinish = true
        }

        open var name: String = ""
        open var branch: String = "master"

        open override func validate() throws {
            if let repo = self.workspace.findAllRepo(name: self.name) {
                throw UserError("Repo `\(String(describing: self.name))` exists: \(repo.path)")
            }
            try super.validate()
        }

        open override func run() throws {
            try super.run()
            let feature = self.config.currentFeature
            var repo: MBConfig.Repo!
            UI.section("Init git repository") {
                repo = MBConfig.Repo(name: self.name, feature: UI.feature!)
                repo.baseGitPointer = .branch(self.branch)
                UI.log(verbose: "Repository Path: `\(repo.path)`")
            }
            try UI.section("Checkout workspace") {
                try UI.log(verbose: "Add `\(repo.name)` to feature `\(feature.name)`") {
                    try repo.createOriginRepository()
                    feature.add(repo: repo)
                }
                self.config.save()
                try repo.work()
                guard let workRepo = repo.workRepository else {
                    throw RuntimeError("The work repository error: \(repo.workingPath)")
                }
                try UI.log(verbose: "Checkout \(GitPointer.branch(self.branch))") {
                    try workRepo.checkout(.branch(self.branch), basePointer: .branch("master"))
                }
                if !feature.free {
                    try UI.log(verbose: "Checkout feature `\(feature.name)`") {
                        try workRepo.checkout(.branch(repo.featureBranch!), basePointer: .branch(self.branch))
                    }
                }
            }
        }
    }
}
