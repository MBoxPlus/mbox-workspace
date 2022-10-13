//
//  GitSheetStatus.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2020/6/1.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBCommander.GitSheet {
    open class Status: GitSheet {
        open class override var description: String? {
            return "Show git status for every repo"
        }

        open override func run() throws {
            try super.run()
            let lines = self.config.currentFeature.repos.map { getInfo(repo: $0) }

            UI.log(info: formatTable(lines).joined(separator: "\n"))
        }

        open func getInfo(repo: MBConfig.Repo) -> Row {
            var v = [[repo.name]]
            v << self.getBranch(repo: repo)
            v << self.getAheadAndBehind(repo: repo)
            if !self.config.currentFeature.free {
                v << self.getMergeStatus(repo: repo)
            }
            return Row(columns: v)
        }

        open func getBranch(repo: MBConfig.Repo) -> [String] {
            guard let git = repo.workRepository?.git,
                let desc = try? git.currentDescribe() else { return [] }
            var v: String
            if desc.isBranch {
                v = "[\(desc.value)]"
            } else {
                v = "[\(desc.type): \(desc.value)]"
            }
            if git.hasConflicts {
                v.append("!".ANSI(.red))
            } else if git.isClean {
                v.append(" ")
            } else {
                v.append("*")
            }
            return [v]
        }

        open func getAheadAndBehind(repo: MBConfig.Repo) -> [String] {
            guard let git = repo.workRepository?.git,
                let currentBranch = git.currentBranch,
                let trackBranch = git.trackBranch() else {
                return []
            }
            guard let info = try? git.aheadBehind(currentBranch: currentBranch, otherBranch: trackBranch) else {
                return []
            }
            var v = [String]()
            var ahead = "↑\(info.ahead)"
            if info.ahead > 0 {
                ahead = ahead.ANSI(.yellow)
            }
            v.append(ahead)

            var behind = "↓\(info.behind)"
            if info.behind > 0 {
                behind = behind.ANSI(.yellow)
            }
            v.append(behind)
            return v
        }

        open func getMergeStatus(repo: MBConfig.Repo) -> [String] {
            guard let git = repo.workRepository?.git,
                let targetBranch = repo.targetBranch else {
                    return []
            }
            guard let currentCommit = git.currentCommit,
                let remoteTargetBranch = git.trackBranch(targetBranch),
                let otherCommit = try? git.commit(for: .branch(remoteTargetBranch)) else {
                    return []
            }
            guard let info = try? git.aheadBehind(currentCommit: currentCommit, otherCommit: otherCommit) else {
                return []
            }

            var v = [String]()

            v.append("->")
            v.append(targetBranch)

            var behind = "↳\(info.behind)"
            if info.behind > 0 {
                behind = behind.ANSI(.yellow)
            }
            v.append(behind)

            var ahead = "↰\(info.ahead)"
            if info.ahead > 0 {
                ahead = ahead.ANSI(.yellow)
            }
            v.append(ahead)

            return v
        }
    }
}

