//
//  MBConfig.Repo.swift
//  MBoxCore
//
//  Created by Whirlwind on 2018/8/29.
//  Copyright © 2018 Bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBConfig.Repo {

    // MARK: - Work
    public func work(useCache: Bool = true, reset: Bool = false) throws {
        try UI.log(verbose: "Make repository work") {
            if self.workRepository != nil {
                UI.log(verbose: "Repo `\(name)` is working!")
                return
            }
            guard let oriRepo = self.originRepository else {
                throw RuntimeError("No store path: `\(self.path)`.")
            }

            let workPath = self.workingPath
            if let git = oriRepo.git, MBSetting.merged.workspace.useWorktree {
                let name = self.workspace.rootPath.lastPathComponent
                try git.removeWorkTree(name, path: workPath)
                try git.addWorkTree(name: name, path: workPath, head: nil, checkout: false)
            } else {
                let storePath = self.path
                try UI.log(verbose: "Move `\(workspace.relativePath(storePath))` -> `\(workspace.relativePath(workPath))`") {
                    try FileManager.default.moveItem(atPath: storePath, toPath: workPath)
                }
                let relativePath = workPath.relativePath(from: storePath.deletingLastPathComponent)
                try UI.log(verbose: "Link `\(workspace.relativePath(storePath))` -> `\(relativePath)`") {
                    try FileManager.default.createSymbolicLink(atPath: storePath,
                                                               withDestinationPath: relativePath)
                }
            }
            guard let workRepo = self.workRepository else {
                return
            }
            var shouldReset = reset
            let cachePath = self.worktreeCachePath
            if cachePath.isDirectory {
                if useCache {
                    try UI.log(verbose: "Move Cache `\(workspace.relativePath(cachePath))` -> `\(workspace.relativePath(self.workingPath))`") {
                        try? FileManager.default.removeItem(atPath: cachePath.appending(pathComponent: ".git"))
                        try FileManager.default.moveItem(atPath: self.workingPath.appending(pathComponent: ".git"), toPath: cachePath.appending(pathComponent: ".git"))
                        try FileManager.default.removeItem(atPath: self.workingPath)
                        try FileManager.default.moveItem(atPath: cachePath, toPath: self.workingPath)
                        shouldReset = true
                    }
                } else {
                    try UI.log(verbose: "Remove Cache `\(workspace.relativePath(cachePath))`") {
                        try FileManager.default.removeItem(atPath: cachePath)
                    }
                }
            }
            if shouldReset {
                UI.log(verbose: "Reset files") {
                    try? workRepo.git?.reset(hard: true)
                }
            } else {
                UI.log(verbose: "Unstage files") {
                    try? workRepo.git?.reset(hard: false)
                }
            }
            try workRepo.includeGitConfig()
        }
    }
}
