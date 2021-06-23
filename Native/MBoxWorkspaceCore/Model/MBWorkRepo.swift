//
//  MBWorkRepo.swift
//  MBoxWorkspaceCore
//
//  Created by 詹迟晶 on 2021/3/18.
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
        if let git = self.git, let commit = git.currentCommit {
            try git.setHEAD(.commit(commit))
        }
        let path = self.model.path
        if !self.path.isExists {
            // Do nothing
            UI.log(verbose: "`\(Workspace.relativePath(self.path))` not exists.")
        } else if !path.isExists || path.isSymlink {
            try UI.log(verbose: "Move `\(Workspace.relativePath(self.path))` -> `\(Workspace.relativePath(path))`") {
                try? FileManager.default.removeItem(atPath: path)
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
                try FileManager.default.moveItem(atPath: self.path.appending(pathComponent: ".git"), toPath: path.appending(pathComponent: ".git"))
                try FileManager.default.removeItem(atPath: self.path)
            }
        } else if self.model.originRepository != nil {
            try UI.log(verbose: "Remove `\(Workspace.relativePath(self.path))`") {
                try FileManager.default.removeItem(atPath: self.path)
            }
        } else {
            try UI.log(verbose: "Move `\(Workspace.relativePath(self.path))` -> `\(Workspace.relativePath(path))`") {
                try? FileManager.default.removeItem(atPath: path)
                try FileManager.default.moveItem(atPath: self.path, toPath: path)
            }
        }
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

        // 判断 target 是否存在
        let realTargetPointer = UI.log(verbose: "Check target \(targetPointer) exists") {
            return git.pointer(for: targetPointer)
        }

        if let realTargetPointer = realTargetPointer {
            // target 存在，直接切换
            try git.checkout(targetPointer, basePointer: realTargetPointer, create: targetPointer != realTargetPointer)
        } else {
            // target 不存在，分析 Base Branch
            if let basePointer = basePointer {
                if targetPointer == basePointer {
                    throw RuntimeError("Could not find the \(basePointer)")
                }
                // 判断 Base Branch 是否存在
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
                try git.checkout(targetPointer, create: false)
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
