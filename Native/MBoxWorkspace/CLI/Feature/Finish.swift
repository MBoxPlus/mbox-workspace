//
//  Finish.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/7/1.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBCommander.Feature {
    open class Finish: Feature {

        open class override var description: String? {
            return "Finish current feature"
        }

        open override class var flags: [Flag] {
            var flags = [Flag]()
            flags << Flag("force", description: "Force remove current feature if there are some changes")
            return flags + super.flags
        }

        open override func setup(argv: ArgumentParser) throws {
            try super.setup(argv: argv)
            self.force = self.shiftFlag("force")
            self.showStatusAtFinish = true
        }

        public var force: Bool = false

        open override func validate() throws {
            if self.config.currentFeature.free {
                throw UserError("Could not finish the Free Mode.")
            }
            let uncleanedRepos = try self.config.currentFeature.repos.filter { repo -> Bool in
                guard let git = repo.workRepository?.git else {
                    throw RuntimeError("The git status is error in repo `\(repo)`")
                }
                return !git.isClean
            }
            if uncleanedRepos.count > 0 && !self.force {
                UI.log(warn: "以下仓库中有未提交文件，无法结束当前 Feature:",
                       items: uncleanedRepos.map { $0.name })
                throw UserError("Could not finish unclean repos, you can use `--force` flag to force finish.")
            }
            try super.validate()
        }

        open override func run() throws {
            try super.run()
            let featureName = self.config.currentFeature.name

            try UI.section("Switch To Free Mode") {
                try self.invoke(Free.self)
            }

            try UI.section("Remove Feature `\(featureName)`") {
                let argv = ArgumentParser(parser: self.argv)
                argv.unshift(argument: featureName)
                try self.invoke(MBCommander.Feature.Remove.self, argv: argv)
            }
        }
    }
}
