//
//  MBWorkRepo.swift
//  MBoxWorkspaceCore
//
//  Created by Whirlwind on 2021/3/18.
//  Copyright © 2021 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit
open class MBWorkRepo: MBRepo {
    open weak var model: MBConfig.Repo!

    public init?(model: MBConfig.Repo) {
        super.init(path: model.workingPath)
        self.model = model
    }

    // MARK: - Package Name
    dynamic
    open override func fetchPackageNames() -> [String] {
        return super.fetchPackageNames()
    }

    // MARK: - Setting
    open lazy var setting: MBSetting = self.loadSetting()

    private func loadSetting() -> MBSetting {
        let settingPath = path.appending(pathComponent: ".mboxconfig")
        return MBSetting.load(fromFile: settingPath, source: "Workspace/\(self)")
    }

    // MARK: - Cache
    open func cache() throws {
        guard let originGit = self.model.originRepository?.git else {
            throw RuntimeError("`\(Workspace.relativePath(self.model.path))` not exists.")
        }
        if !self.path.isExists {
            UI.log(verbose: "`\(Workspace.relativePath(self.path))` not exists.")
        } else {
            guard let git = self.git, let commit = git.currentCommit else {
                throw RuntimeError("`\(Workspace.relativePath(self.path))` is NOT a git repository.")
            }
            try git.setHEAD(.commit(commit))

            let fm = FileManager.default

            // Remove symblink in Store Path
            let storePath = self.model.path
            if storePath.isSymlink {
                try UI.log(verbose: "Remove symlink `\(Workspace.relativePath(storePath))`") {
                    try fm.removeItem(atPath: storePath)
                }
            }

            if !git.isWorkTree {
                if MBSetting.merged.workspace.useWorktree {
                    // Move `.git/` to Store Path
                    let gitPath = self.path.appending(pathComponent: ".git")
                    let gitTargetPath = storePath.appending(pathComponent: ".git")
                    if gitTargetPath.isDirectory {
                        throw RuntimeError("`\(storePath)` exists, could not store the repo.")
                    }
                    try UI.log(verbose: "Move `\(Workspace.relativePath(gitPath))` -> `\(Workspace.relativePath(gitTargetPath))`") {
                        try fm.createDirectory(atPath: storePath, withIntermediateDirectories: true)
                        try fm.moveItem(atPath: gitPath, toPath: gitTargetPath)
                    }
                } else {
                    // Move Workcopy to Store Path
                    try UI.log(verbose: "Move `\(Workspace.relativePath(self.path))` -> `\(Workspace.relativePath(storePath))`") {
                        try fm.createDirectory(atPath: storePath.deletingLastPathComponent, withIntermediateDirectories: true)
                        try fm.moveItem(atPath: self.path, toPath: storePath)
                    }
                }
            }

            if MBSetting.merged.workspace.useWorktree ||
                !self.model.originRepository!.isInWorkspace {
                // Move workcopy to Cache Path
                let cachePath = self.model.worktreeCachePath
                try UI.log(verbose: "Cache `\(workspace.relativePath(self.path))` -> `\(workspace.relativePath(cachePath))`") {
                    if cachePath.isExists {
                        try fm.removeItem(atPath: cachePath)
                    }
                    try fm.createDirectory(atPath: cachePath.deletingLastPathComponent, withIntermediateDirectories: true, attributes: nil)
                    try fm.moveItem(atPath: self.path, toPath: cachePath)
                }
            }
        }
        try originGit.pruneWorkTree(self.workspace.name)
    }

    // MARK: - Remove
    open func remove() throws {
        try self.cache()
        try self.model.originRepository?.remove(with: self.model)
    }

    public func checkout(_ targetPointer: GitPointer,
                         basePointer: GitPointer? = nil,
                         baseRemote: Bool = false,
                         setUpStream: Bool = true) throws {
        guard let git = git else { return }
        if (try git.currentDescribe()) == targetPointer {
            UI.log(verbose: "The current status is already \(targetPointer), skip checkout.")
            return
        }

        let realTargetPointer = UI.log(verbose: "Check target \(targetPointer) exists") {
            return git.pointer(for: targetPointer)
        }

        if let realTargetPointer = realTargetPointer {
            try git.checkout(targetPointer, basePointer: realTargetPointer, create: targetPointer != realTargetPointer)
        } else {
            if let basePointer = basePointer {
                if targetPointer == basePointer {
                    throw RuntimeError("Could not find the \(basePointer)")
                }
                let realBasePointer = UI.log(verbose: "Check base \(basePointer) exists") {
                    return git.pointer(for: basePointer, local: !baseRemote, remote: true)
                }
                if let realBasePointer = realBasePointer {
                    try git.checkout(targetPointer, basePointer: realBasePointer, create: true)
                } else if git.isUnborn {
                    try git.checkout(targetPointer, create: true)
                } else {
                    throw RuntimeError("Could not find the base \(basePointer)")
                }
            } else {
                try git.checkout(targetPointer, create: true)
            }
        }

        if targetPointer.isBranch && setUpStream {
            if let curBranch = git.currentBranch, git.trackBranch() == nil {
                UI.log(verbose: "Setup upstream branch with auto match mode") {
                    if let remoteBranch = git.remoteBranch(named: curBranch) {
                        UI.log(verbose: "Set the upstream branch: \(remoteBranch.name)") {
                            git.setTrackBranch(local: curBranch, remote: remoteBranch.name)
                        }
                    } else {
                        UI.log(verbose: "There is not same branch name `\(curBranch)` in the remote, Skip it.")
                    }
                }
            }
        }
    }
}

extension MBWorkRepo {
    dynamic
    open var pathsToLink: [String] {
        return self.setting.value(forPath: "workspace.symlinks")
    }
}
