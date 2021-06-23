//
//  Status+Git.swift
//  MBoxWorkspace
//
//  Created by 詹迟晶 on 2021/2/24.
//  Copyright © 2021 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit
import MBoxWorkspaceCore

extension MBCommander.Status {
    open class Git: MBCommanderStatus {
        public static var supportedAPI: [APIType] {
            return [.api, .plain]
        }

        public static var title: String {
            return "git"
        }

        public var feature: MBConfig.Feature

        public required init(feature: MBConfig.Feature) {
            self.feature = feature
        }

        public func APIData() throws -> Any?  {
            return Dictionary(uniqueKeysWithValues: self.feature.repos.map { ($0.name, $0.url) })
        }

        public func plainData() throws -> [String]?  {
            return self.feature.repos.compactMap { $0.url }
        }
    }

    open class func gitInfo(repo: MBConfig.Repo) throws -> [String: Any] {
        guard let workRepo = repo.workRepository,
              let git = workRepo.git else {
            return [:]
        }

        var gitInfo: [String: Any] = [:]

        if let currentCommit = git.currentCommit {
            gitInfo["commit"] = currentCommit
        }

        gitInfo["has_conflicts"] = git.hasConflicts
        gitInfo["is_clean"] = git.isClean

        if let currentBranch = git.currentBranch, let trackBranch = git.trackBranch() {
            if let infoRemote = try? git.aheadBehind(currentBranch: currentBranch, otherBranch: trackBranch) {
                gitInfo["ahead_remote"] = infoRemote.ahead
                gitInfo["behind_remote"] = infoRemote.behind
            }
        }

        if let targetBranch = repo.targetBranch, let currentCommit = git.currentCommit,
           let remoteTargetBranch = git.trackBranch(targetBranch),
           let otherCommit = try? git.commit(for: .branch(remoteTargetBranch)) {
            if let infoTarget = try? git.aheadBehind(currentCommit: currentCommit, otherCommit: otherCommit) {
                gitInfo["ahead_target"] = infoTarget.ahead
                gitInfo["behind_target"] = infoTarget.behind
            }

        }

        return gitInfo
    }

    open class func getAheadAndBehind(git: GitHelper) -> [String] {
        guard let currentBranch = git.currentBranch,
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

    open class func getMergeStatus(git: GitHelper, targetBranch: String) -> [String] {
        guard let currentCommit = git.currentCommit,
              let remoteTargetBranch = git.trackBranch(targetBranch),
              let otherCommit = try? git.commit(for: .branch(remoteTargetBranch)) else {
            return []
        }
        guard let info = try? git.aheadBehind(currentCommit: currentCommit, otherCommit: otherCommit) else {
            return []
        }

        var v = [String]()

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
