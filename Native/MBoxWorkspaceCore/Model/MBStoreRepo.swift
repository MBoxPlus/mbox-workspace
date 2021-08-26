//
//  MBStoreRepo.swift
//  MBoxWorkspaceCore
//
//  Created by Whirlwind on 2021/3/18.
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
    func `import`(to targetDir: String) throws {
        if isInWorkspace { return }
        try? FileManager.mkdir_p(targetDir)
        guard var git = self.git else { throw UserError("[\(self.name)] The git error!") }
        let gitDir = git.commonDir

        // Replace `.git` file with real git repository
        let targetGit = targetDir.appending(pathComponent: ".git")
        try UI.log(verbose: "Copy `\(gitDir)` to `\(Workspace.relativePath(targetDir))`") {
            if targetGit.isExists {
                throw UserError("`\(targetGit)` exists, could not to import.")
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
        if !self.isInWorkspace {
            UI.log(verbose: "Repository is not in workspace, Skip remove.")
            let name = self.workspace.name
            try git?.pruneWorkTree(name, force: true)
        } else {
            try UI.log(verbose: "Delete `\(self.path)`") {
                try FileManager.default.removeItem(atPath: self.path)
            }
        }
    }

    open func remove(with config: MBConfig.Repo) throws {
        guard let git = self.git else {
            return
        }
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
