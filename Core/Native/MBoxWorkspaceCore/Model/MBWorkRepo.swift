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
        return MBSetting.load(fromFile: settingPath, name: "Workspace/\(self)")
    }

    // MARK: - File Manager
    private var fileCache = [String: [String]]()
    private func pathsWithCache(for regex: String) -> [String] {
        if let paths = self.fileCache[regex] { return paths }
        let paths: [String] = FileManager.glob(self.path.appending(pathComponent: regex))
            .map { $0.relativePath(from: self.path) }
        self.fileCache[regex] = paths
        return paths
    }

    public func path(for regex: String, filter: ((String) -> Bool)? = nil) -> String? {
        let paths = self.pathsWithCache(for: regex)
        if let filter = filter {
            for path in paths where filter(path) {
                return path
            }
        } else {
            return paths.first
        }
        return nil
    }

    public func path(for regex: String? = nil, defaults: [String] = [], filter: ((String) -> Bool)? = nil) -> String? {
        if let regex = regex {
            if let path = self.path(for: regex, filter: filter) {
                return path
            }
        }
        for regex in defaults {
            if let path = self.path(for: regex, filter: filter) {
                return path
            }
        }
        return nil
    }

    public func paths(for regex: String, filter: ((String) -> Bool)? = nil) -> [String] {
        let paths = self.pathsWithCache(for: regex)
        if let filter = filter {
            return paths.filter(filter)
        }
        return paths
    }

    public func paths(for regex: [String], filter: ((String) -> Bool)? = nil) -> [String] {
        return regex.flatMap {
            self.paths(for: $0, filter: filter)
        }
    }

    public func paths(for regex: [String]? = nil, defaults: [String] = [], filter: ((String) -> Bool)? = nil) -> [String] {
        if let regex = regex {
            let paths = self.paths(for: regex, filter: filter)
            if !paths.isEmpty {
                return paths
            }
        }
        return self.paths(for: defaults, filter: filter)
    }

    public func paths(for regex: [String: String], filter: ((String) -> Bool)? = nil) -> [String: String] {
        var result = [String: String]()
        for (name, r) in regex {
            if let path = self.path(for: r, filter: filter) {
                result[name] = path
            }
        }
        return result
    }

    public func paths(for regex: [String: String]? = nil, defaults: (String, [String])? = nil, filter: ((String) -> Bool)? = nil) -> [String: String] {
        if let regex = regex {
            let paths = self.paths(for: regex, filter: filter)
            if !paths.isEmpty {
                return paths
            }
        }
        if let defaults = defaults {
            for defaultRegex in defaults.1 {
                if let path = self.path(for: defaultRegex, filter: filter) {
                    return [defaults.0: path]
                }
            }
        }
        return [:]
    }

    // MARK: - Cache
    open func cache() throws {
        if !self.path.isExists {
            UI.log(verbose: "`\(Workspace.relativePath(self.path))` not exists.")
            return
        }
        let fm = FileManager.default

        guard let git = self.git, let commit = git.currentCommit else {
            throw RuntimeError("`\(Workspace.relativePath(self.path))` is NOT a git repository.")
        }

        let useWorktree = git.isWorkTree
        if !useWorktree {
            // Remove symblink in Store Path
            let storePath = self.model.path
            if storePath.isSymlink {
                try UI.log(verbose: "Remove symlink `\(Workspace.relativePath(storePath))`") {
                    try fm.removeItem(atPath: storePath)
                }
            }
            if storePath.isExists {
                throw RuntimeError("`\(Workspace.relativePath(storePath))` exists.")
            }
            try git.setHEAD(.commit(commit))
            // Move `.git/` to Store Path
            let gitPath = self.path.appending(pathComponent: ".git")
            let gitTargetPath = storePath.appending(pathComponent: ".git")
            try UI.log(verbose: "Move `\(Workspace.relativePath(gitPath))` -> `\(Workspace.relativePath(gitTargetPath))`") {
                try fm.createDirectory(atPath: storePath, withIntermediateDirectories: true)
                try fm.moveItem(atPath: gitPath, toPath: gitTargetPath)
            }
            self.model.reloadOriginRepository()
        }

        // Move workcopy to Cache Path
        let cachePath = self.model.worktreeCachePath
        try UI.log(verbose: "Cache `\(workspace.relativePath(self.path))` -> `\(workspace.relativePath(cachePath))`") {
            if cachePath.isExists {
                try fm.removeItem(atPath: cachePath)
            }
            try fm.createDirectory(atPath: cachePath.deletingLastPathComponent, withIntermediateDirectories: true, attributes: nil)
            try fm.moveItem(atPath: self.path, toPath: cachePath)
        }

        if useWorktree {
            try self.model.originRepository?.git?.removeWorkTree(self.workspace.name, path: self.path)
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
                         setUpStream: Bool = true,
                         force: Bool = false) throws {
        guard let git = git else { return }
        if (try git.currentDescribe()) == targetPointer {
            UI.log(verbose: "The current status is already \(targetPointer), skip checkout.")
            return
        }

        let realTargetPointer = UI.log(verbose: "Check target \(targetPointer) exists") {
            return git.pointer(for: targetPointer)
        }

        if let realTargetPointer = realTargetPointer {
            UI.log(info: "The \(realTargetPointer) exist! Checkout it.")
            try git.checkout(targetPointer, basePointer: realTargetPointer, create: targetPointer != realTargetPointer, force: force)
        } else {
            if let basePointer = basePointer {
                if targetPointer == basePointer {
                    throw RuntimeError("Could not find the \(basePointer)")
                }
                let realBasePointer = UI.log(verbose: "Check base \(basePointer) exists") {
                    return git.pointer(for: basePointer, local: !baseRemote, remote: true)
                }
                if let realBasePointer = realBasePointer {
                    UI.log(info: "Create \(targetPointer) base on \(realBasePointer)")
                    try git.checkout(targetPointer, basePointer: realBasePointer, create: true, force: force)
                } else if git.isUnborn {
                    UI.log(info: "Create a first \(targetPointer)")
                    try git.checkout(targetPointer, create: true, force: force)
                } else {
                    throw RuntimeError("Could not find the base \(basePointer)")
                }
            } else {
                UI.log(info: "Create \(targetPointer)")
                try git.checkout(targetPointer, create: true, force: force)
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
    public var pathsToLink: [String] {
        return self.setting.value(forPath: "workspace.symlinks")
    }
}
