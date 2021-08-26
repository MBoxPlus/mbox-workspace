//
//  FeatureMerge.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/9/20.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit
import MBoxWorkspaceCore

extension MBCommander.Feature {
    open class FeatureMerge: Feature {
        open class override var name: String? {
            return "merge"
        }

        open class override var description: String? {
            return "Create a MR to target branch"
        }

        dynamic
        open override class var flags: [Flag] {
            var flags = [Flag]()
            flags << Flag("force", description: "Force create the MR if there are some changes not be committed")
            flags << Flag("forward", description: "Create the MR with repos which forward target branch")
            return flags + super.flags
        }

        dynamic
        open override func setup() throws {
            try super.setup()
            self.force = self.shiftFlag("force")
            self.forward = self.shiftFlag("forward")
        }

        dynamic
        open override func run() throws {
            try super.run()
            try UI.section("Check Feature Status") {
                try self.checkFeature()
            }
            try UI.section("Check Git Status") {
                try self.checkGitStatus()
            }
            try UI.section("Check Git Remote Branch") {
                try self.checkRemoteBranch()
            }
            if self.feature.free {
                UI.log(verbose: "Skip check merge conflict for free mode.")
            } else {
                try UI.section("Check Merge Conflict") {
                    try self.checkMergeConflict()
                }
            }
            try UI.section("Push To Remote") {
                try self.pushRemote()
            }
            if self.repos.isEmpty {
                UI.log(info: "No repository to merge.")
            } else {
                UI.log(info: "The repositories to merge:",
                            items: self.repos.map{ $0.name })
            }
        }

        dynamic
        open override func validate() throws {
            try super.validate()
        }

        open var feature: MBConfig.Feature {
            return self.config.currentFeature
        }

        open var force: Bool?
        open var forward: Bool?
        open var repos: [MBConfig.Repo] = []

        open func checkFeature() throws {
            try feature.eachRepos { repo in
                guard let git = repo.workRepository?.git else { return }
                let des = try git.currentDescribe()
                if self.feature.free {
                    if !des.isBranch {
                        throw UserError("[\(repo)] is \(des), it must be a branch.")
                    }
                } else {
                    let featureBranch = repo.featureBranch!
                    if !des.isBranch || des.value != featureBranch {
                        throw UserError("[\(repo)] is \(des), it is different with `\(featureBranch)`")
                    }
                }
            }
        }

        open func checkGitStatus() throws {
            try feature.eachRepos { repo in
                guard let git = repo.workRepository?.git else {
                    throw RuntimeError("[\(repo)] There is something wrong for the git repository.")
                }
                guard let url = git.url, !url.isEmpty else {
                    throw UserError("[\(repo)] There is not a remote url.")
                }

                if git.isClean { return }

                UI.log(info: "[\(repo)] has changes but NOT be committed.".ANSI(.red))
                if self.force == nil {
                    try UI.with(verbose: true) {
                        _ = git.isClean
                        if !UI.gets("Do you continue finish this feature?", default: false) {
                            throw UserError("User Abort")
                        }
                    }
                } else if self.force == false {
                    throw UserError("[\(repo)] has changes but NOT be committed.")
                }
            }
        }

        open func checkRemoteBranch() throws {
            try feature.eachRepos { repo in
                guard let git = repo.workRepository?.git else { return }
                try git.fetch()
                let currentBranch = git.currentBranch!
                var remoteBranch = git.trackBranch()
                if remoteBranch == nil {
                    remoteBranch = git.remoteBranch(named: currentBranch)?.name
                    if remoteBranch != nil {
                        git.setTrackBranch(local: currentBranch, remote: remoteBranch)
                    }
                }
                if let remoteBranch = remoteBranch {
                    let status = try git.checkMergeStatus(curBranch: currentBranch, target: .branch(remoteBranch))
                    switch status {
                    case .diverged:
                        throw UserError("[\(repo)] Need Merge with remote branch `\(remoteBranch)`.")
                    case .behind:
                        try git.pull()
                    case .forward: break
                    default:
                        break
                    }
                }
            }
        }

        open func checkMergeConflict() throws {
            try feature.eachRepos { repo in
                guard let git = repo.workRepository?.git else { return }
                let baseBranch = (repo.targetBranch ?? repo.baseBranch)!
                guard let remoteBaseBranch = git.trackBranch(baseBranch) ?? git.remoteBranch(named: baseBranch)?.longName else {
                    throw UserError("[\(repo)] Could not find the remote branch for base branch `\(baseBranch)")
                }
                let status = try git.checkMergeStatus(curBranch: git.currentBranch, target: .branch(remoteBaseBranch))
                switch status {
                case .forward:
                    self.repos << repo
                case .diverged:
                    let conflict = try git.hasMergeConflict(with: .branch(remoteBaseBranch))
                    if conflict {
                        throw UserError("[\(repo)] has merge conflict with branch `\(remoteBaseBranch)`.")
                    } else {
                        UI.log(verbose: "Ready for merge.")
                    }
                    self.repos << repo
                case .uptodate, .behind:
                    guard let forard1 = self.forward, forard1 else {
                        self.repos << repo
                        return
                    }
                default: break
                }
            }
        }

        open func pushRemote() throws {
            for repo in repos {
                try UI.log(verbose: "[\(repo)]") {
                    guard let git = repo.workRepository?.git else { return }
                    guard let currentCommit = git.currentCommit else {
                        throw RuntimeError("There are something wrong in repo \(repo).")
                    }
                    if let trackBranch = git.trackBranch(),
                        let remoteCommit = try? git.commit(for: .branch(trackBranch)) {
                        if currentCommit == remoteCommit {
                            UI.log(verbose: "Already up to date.")
                            return
                        }
                    }
                    try git.push()
                }
            }
        }
    }
}
