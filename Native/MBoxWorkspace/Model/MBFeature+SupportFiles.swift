//
//  MBConfig.Feature+SupportFiles.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2021/1/29.
//  Copyright © 2021 bytedance. All rights reserved.
//

import MBoxCore

extension MBConfig.Feature {
    private static let supportFileListName = ".filelist"

    dynamic
    public var supportFiles: [String] {
        return []
    }

    public var supportDir: String {
        return MBProcess.shared.workspace!.configDir.appending(pathComponent: "features").appending(pathComponent: name)
    }

    public func generateSupportFileListFile(_ path: String, content: [String]) throws {
        UI.log(verbose:"Create `\(Self.supportFileListName)` file in `\(path)`")

        if !(content as NSArray).write(toFile: path, atomically: true) {
            throw RuntimeError("Failed to generate `\(Self.supportFileListName)` file for an unknown reason")
        }
    }

    public func readSupportFileListFile(_ path: String) throws -> [String] {
        if let files = NSArray(contentsOf: URL(fileURLWithPath: path)) as? [String] {
            return files
        }
        throw RuntimeError("Failed to read `\(Self.supportFileListName)` file for an unknown reason")
    }

    dynamic
    public func backupSupportFiles(removeSourceFiles: Bool) throws {
        try self.backupSupportFiles(supportFiles, to: supportDir, move: removeSourceFiles)
    }

    dynamic
    public func backupSupportFiles(_ files: [String], to: String, move: Bool) throws {
        if to.isExists {
            try FileManager.default.removeItem(atPath: to)
        }

        if files.isEmpty {
            return
        }

        try FileManager.default.createDirectory(atPath: to, withIntermediateDirectories: true, attributes: nil)

        for file in files {
            let path = MBProcess.shared.workspace!.rootPath.appending(pathComponent: file)
            guard path.isExists else {
                continue
            }
            let target = to.appending(pathComponent: file)

            let targetDir = target.deletingLastPathComponent
            if !targetDir.isEmpty {
                try FileManager.default.createDirectory(atPath: targetDir, withIntermediateDirectories: true, attributes: nil)
            }

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

        let supportFileListPath = to.appending(pathComponent: Self.supportFileListName)
        try generateSupportFileListFile(supportFileListPath, content: files)
    }

    dynamic
    public func restoreSupportFiles() throws {
        try self.restoreSupportFiles(from: supportDir)
    }

    public func restoreSupportFiles(from dir: String) throws {
        if !dir.isDirectory { return }

        let files: [String]
        let supportFileListPath = dir.appending(pathComponent: Self.supportFileListName)
        if supportFileListPath.isFile {
            files = try self.readSupportFileListFile(supportFileListPath)
        } else {
            files = try FileManager.default.contentsOfDirectory(atPath: dir)
        }
        try self.restoreSupportFiles(from: dir, files: files)

        try FileManager.default.removeItem(atPath: dir)
    }

    private func restoreSupportFiles(from dir: String, files: [String]) throws {
        try files.forEach {(file) in
            let path = dir.appending(pathComponent: file)
            guard path.isExists else {
                return
            }
            let target = MBProcess.shared.workspace!.rootPath.appending(pathComponent: file)

            if target.isExists {
                try FileManager.default.removeItem(atPath: target)
            } else {
                let targetDir = target.deletingLastPathComponent
                if !targetDir.isEmpty {
                    try FileManager.default.createDirectory(atPath: targetDir, withIntermediateDirectories: true, attributes: nil)
                }
            }
            try UI.log(verbose: "Move `\(Workspace.relativePath(path))` -> `\(file)`") {
                try FileManager.default.moveItem(atPath: path, toPath: target)
            }
        }
    }

    public func cleanSupportFiles() throws {
        guard supportDir.isDirectory else { return }
        try UI.log(verbose: "Remove support files for feature `\(name)`") {
            try FileManager.default.removeItem(atPath: supportDir)
        }
    }
}
