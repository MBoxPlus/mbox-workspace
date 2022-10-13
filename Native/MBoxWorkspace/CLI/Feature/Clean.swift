//
//  Clean.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/11/11.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBCommander.Feature {
    open class Clean: Feature {
        open class override var description: String? {
            return "Clean merged feature"
        }

        open override func run() throws {
            try super.run()
            let features = try UI.section("Check Features") {
                return try mergedFeatures()
            }
            if features.isEmpty {
                UI.log(info: "Not feature to clean.")
                return
            }
            try UI.section("Clean Features") {
                for feature in features {
                    try UI.section("[\(feature)]") {
                        try invoke(Remove.self, argv: ArgumentParser(arguments: [feature.name]))
                    }
                }
            }
        }

        open lazy var fetched = [MBConfig.Repo]()

        open func checkMerged(repo: MBConfig.Repo) throws -> Bool {
            return try UI.log(verbose: "Check repo `\(repo)`") {
                guard let oriRepo = repo.originRepository else {
                    UI.log(verbose: "The repository does not exist, skip check.")
                    return true
                }
                guard let git = oriRepo.git else {
                    UI.log(verbose: "The git is invalid, disallow to remove the feature.")
                    return false
                }
                guard let featureBranch = repo.featureBranch else {
                    UI.log(verbose: "The feature branch is not found.")
                    return false
                }
                let localGitPointer = GitPointer.branch(featureBranch)
                if !localGitPointer.isBranch {
                    UI.log(verbose: "The \(localGitPointer) is not a branch, skip check.")
                    return true
                }
                if !git.exists(gitPointer: localGitPointer, local: true, remote: false) {
                    UI.log(verbose: "The local \(localGitPointer) does not exist, skip check.")
                    return true
                }
                guard let baseGitPointer = repo.baseGitPointer, baseGitPointer.isBranch else {
                    UI.log(verbose: "The base branch is invalid, disallow to remove the feature.")
                    return false
                }
                guard let trackBranch = git.trackBranch(baseGitPointer.value) else {
                    UI.log(verbose: "The track branch for \(baseGitPointer) does not exist, disallow to remove the feature.")
                    return false
                }
                // Check merge status
                var status = try git.checkMergeStatus(curBranch: localGitPointer.value, target: .branch(trackBranch))
                if status == .uptodate || status == .behind {
                    UI.log(verbose: "The local \(localGitPointer) had been merged into branch `\(trackBranch)`, allow to remove the feature.")
                    return true
                }
                // Try fetch the remote
                if !fetched.contains(repo) {
                    try git.fetch()
                    fetched.append(repo)
                    // Retry to check the merge status
                    status = try git.checkMergeStatus(curBranch: localGitPointer.value, target: .branch(trackBranch))
                    if status == .uptodate || status == .behind {
                        UI.log(verbose: "The local \(localGitPointer) had been merged into branch `\(trackBranch)`, allow to remove the feature.")
                        return true
                    }
                }
                UI.log(verbose: "The local \(localGitPointer) is NOT merged into branch `\(trackBranch)`, disallow to remove the feature.")
                return false
            }
        }

        open func mergedFeatures() throws -> [MBConfig.Feature] {
            return try self.config.features.values.filter { feature -> Bool in
                guard !feature.free, !feature.isCurrent else { return false }
                return try UI.section("Check Feature [\(feature)]") {
                    for repo in feature.repos {
                        if try !checkMerged(repo: repo) {
                            return false
                        }
                    }
                    return true
                }
            }
        }

    }
}
