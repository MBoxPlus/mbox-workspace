//
//  MBConfig.Feature+SupportFiles.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2021/1/29.
//  Copyright © 2021 bytedance. All rights reserved.
//

import MBoxCore
import MBoxWorkspaceCore

extension MBConfig.Feature {
    dynamic
    open var supportFiles: [String] {
        return []
    }

    public var supportDir: String {
        return UI.workspace!.configDir.appending(pathComponent: "features").appending(pathComponent: name)
    }

    dynamic
    open func backupSupportFiles(removeSourceFiles: Bool) throws {
        try self.backupSupportFiles(supportFiles, to: supportDir, move: removeSourceFiles)
    }

    open func backupSupportFiles(_ files: [String], to: String, move: Bool) throws {
        if files.isEmpty {
            return
        }

        if to.isExists {
            try FileManager.default.removeItem(atPath: to)
        }
        try FileManager.default.createDirectory(atPath: to, withIntermediateDirectories: true, attributes: nil)

        for file in files {
            let path = UI.workspace!.rootPath.appending(pathComponent: file)
            if path.isExists {
                let target = to.appending(pathComponent: file)
                if move {
                    try UI.log(verbose: "Move `\(file)` -> `\(Workspace.relativePath(target))`") {
                        try FileManager.default.moveItem(atPath: path, toPath: target)
                    }
                } else {
                    try UI.log(verbose: "Copy `\(file)` -> `\(Workspace.relativePath(target))`") {
                        try FileManager.default.copyItem(atPath: path, toPath: target)
                    }
                }
            }
        }
    }

    dynamic
    open func restoreSupportFiles() throws {
        try self.restoreSupportFiles(from: supportDir)
    }

    open func restoreSupportFiles(from dir: String) throws {
        if !supportDir.isDirectory {
            return
        }

        try FileManager.default.contentsOfDirectory(atPath: dir).forEach { (file) in
            let path = dir.appending(pathComponent: file)
            if path.isExists {
                let target = UI.workspace!.rootPath.appending(pathComponent: file)
                if target.isExists {
                    try FileManager.default.removeItem(atPath: target)
                }
                try UI.log(verbose: "Move `\(Workspace.relativePath(path))` -> `\(file)`") {
                    try FileManager.default.moveItem(atPath: path, toPath: target)
                }
            }
        }

        try FileManager.default.removeItem(atPath: dir)
    }

    public func cleanSupportFiles() throws {
        if supportDir.isDirectory {
            try UI.log(verbose: "Remove support files for feature `\(name)`") {
                try FileManager.default.removeItem(atPath: supportDir)
            }
        }
    }
}
