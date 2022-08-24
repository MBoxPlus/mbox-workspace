//
//  Git+Repair.swift
//  MBoxWorkspace
//
//  Created by 詹迟晶 on 2022/2/10.
//  Copyright © 2022 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit
import MBoxWorkspaceCore

extension MBCommander.Git {
    open class Repair: MBCommander {
        open override class var description: String? {
            return "Repair the git worktree path after the workspace is moved."
        }

        open override func run() throws {
            try super.run()
            try self.workspace.eachWorkRepos { workRepo in
                do {
                    try self.repair(repo: workRepo.model)
                } catch {
                    UI.log(error: error.localizedDescription)
                    UI.statusCode = 1
                }
            }
        }

        open func repair(repo: MBConfig.Repo) throws {
            let workingPath = repo.workingPath
            guard workingPath.isDirectory else {
                UI.log(info: "[\(repo)] is not working, skip.")
                return
            }

            let dotGitFilePath = workingPath.appending(pathComponent: ".git")
            guard dotGitFilePath.isFile else {
                UI.log(info: "[\(repo)] is not worktree mode, skip.")
                return
            }

            let originWorktreeDir = try String(contentsOfFile: dotGitFilePath).trimmed.deletePrefix("gitdir:").trimmed
            UI.log(verbose: "`\(self.workspace.relativePath(dotGitFilePath))`: \(originWorktreeDir)")

            let originWorktreeName = try self.parseId(string: originWorktreeDir)
            UI.log(verbose: "Worktree ID: \(originWorktreeName)")

            let worktreeDir = repo.path.appending(pathComponent: ".git/worktrees/\(originWorktreeName)/")
            if !worktreeDir.isDirectory {
                throw RuntimeError("Worktree noexist: `\(worktreeDir)`")
            }

            // Repair `<LinkedWorktree>/.git`
            try UI.log(info: "Update `\(self.workspace.relativePath(dotGitFilePath))`") {
                UI.log(verbose: worktreeDir)
                try "gitdir: \(worktreeDir)".write(toFile: dotGitFilePath, atomically: true, encoding: .utf8)
            }

            // Repair `<Main>/.git/worktrees/<id>/gitdir`
            let gitdirPath = worktreeDir.appending(pathComponent: "gitdir")
            try UI.log(info: "Update `\(self.workspace.relativePath(gitdirPath))`") {
                UI.log(verbose: dotGitFilePath)
                try dotGitFilePath.write(toFile: gitdirPath, atomically: true, encoding: .utf8)
            }

            // Repair `<Main>/.git/worktrees/<id>/commondir`
            let commondirPath = worktreeDir.appending(pathComponent: "commondir")
            try UI.log(info: "Update `\(self.workspace.relativePath(commondirPath))`") {
                let commondir = repo.path.appending(pathComponent: ".git")
                UI.log(verbose: commondir)
                try commondir.write(toFile: commondirPath, atomically: true, encoding: .utf8)
            }
        }

        func parseId(string: String) throws -> String {
            guard let info = try? string.match(regex: ".+/\\.git/worktrees/(.+?)/?$")?.first,
                  info.count == 2 else {
                      throw RuntimeError("Parse Failed: `\(string)`.")
            }
            return info[1]
        }
    }
}
