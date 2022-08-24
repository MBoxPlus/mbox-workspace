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
            self.showStatusAtFinish = []
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
                throw UserError("Could not finish unclean repos: \(uncleanedRepos), you can use `--force` flag to force finish.")
            }

            let feature = self.config.currentFeature
            for repo in feature.repos {
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
                if self.force == true{
                    argv.append(argument:"--force")
                }

                try self.invoke(MBCommander.Feature.Remove.self, argv: argv)  
            }
            
        }

        open func checkMerged(git: GitHelper, featureBranch: String, targetBranch: String) throws -> Bool {
            let status = try git.checkMergeStatus(curBranch: targetBranch, target: .branch(featureBranch))
            return status != .diverged && status != .behind
        }

    }
}
