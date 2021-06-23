//
//  MBStoreRepo.swift
//  MBoxWorkspaceCore
//
//  Created by 詹迟晶 on 2021/3/18.
//  Copyright © 2021 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

open class MBStoreRepo: MBRepo {

    open var isInWorkspace: Bool {
        return self.path.cleanPath.hasPrefix(self.workspace.repoStoreDir.cleanPath)
    }

    // MARK: - Import
    open func `import`(to targetDir: String, mode: Mode) throws {
        if isInWorkspace { return }
        guard mode == .copy || mode == .move else {
            return
        }
        try? FileManager.mkdir_p(targetDir)
        guard var git = self.git else { throw UserError("[\(self.name)] The git error!") }
        let gitDir = git.commonDir
        try UI.log(verbose: "Copy `.git` to `\(Workspace.relativePath(targetDir))`") {
            let targetGit = targetDir.appending(pathComponent: ".git")
            if targetGit.isExists {
                try FileManager.default.removeItem(atPath: targetGit)
            }
            try FileManager.default.copyItem(atPath: gitDir, toPath: targetGit)
        }
        self.path = targetDir
        git = self.git!
        if !git.isWorkTree {
            try? git.cleanWorkTrees()
        }
        if let commit = git.currentCommit {
            try git.setHEAD(.commit(commit))
        }
    }

    // MARK: - Remove
    open func remove() throws {
        guard self.isInWorkspace else {
            UI.log(verbose: "Repository is not in workspace, Skip remove.")
            return
        }
        if git?.isWorkTree == true {
            let name = self.workspace.rootPath.lastPathComponent
            try UI.log(verbose: "Prune worktree `\(name)`") {
                try git?.pruneWorkTree(name, force: true)
            }
        }
        try UI.log(verbose: "Delete `\(self.path)`") {
            try FileManager.default.removeItem(atPath: self.path)
        }
    }

    open func remove(with config: MBConfig.Repo) throws {
        guard let git = self.git else {
            return
        }
        let name = self.workspace.rootPath.lastPathComponent
        _ = try? git.pruneWorkTree(name)
        try git.delete(stash: config.feature.stashName)
        if let branch = config.featureBranch {
            try UI.log(verbose: "Try to delete branch `\(branch)`") {
                if git.exists(gitPointer: .branch(branch)) {
                    if git.currentBranch == branch, let commit = git.currentCommit {
                        try git.checkout(.commit(commit))
                    }
                    try git.delete(branch: branch)
                }
            }
        }
    }
}
