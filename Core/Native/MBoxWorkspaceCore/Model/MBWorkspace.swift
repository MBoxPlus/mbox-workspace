//
//  MBWorkspace.swift
//  MBoxCore
//
//  Created by Whirlwind on 2018/8/28.
//  Copyright © 2018 Bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

open class MBWorkspace: NSObject {

    public static var all = NSMapTable<NSString, MBWorkspace>.strongToWeakObjects()

    public var verbose = false
    public var silent = false

    public lazy var name: String = {
        return rootPath.lastPathComponent
    }()
    public var rootPath: String
    public func fullPath(_ path: String) -> String {
        if path.starts(with: "/") {
            return path
        }
        return self.rootPath.appending(pathComponent: path)
    }
    public func relativePath(_ path: String) -> String {
        if path.hasPrefix(self.rootPath) {
            return path.relativePath(from: self.rootPath)
        } else {
            return path
        }
    }

    public var configDir: String {
        return rootPath.appending(pathComponent:".mbox")
    }
    
    public var hookFileDir: String {
        do {
            try createHookFileDir()
        } catch {}
        return configDir.appending(pathComponent: "hooks")
    }
    
    open func createHookFileDir() throws {
        try FileManager.default.createDirectory(atPath: configDir.appending(pathComponent: "hooks"), withIntermediateDirectories: true, attributes: nil)
    }

    private var _isReady: Bool?
    public var isReady: Bool? {
        set {
            _isReady = newValue
        }
        get {
            return _isReady
        }
    }

    public static func query(rootPath: String) -> MBWorkspace {
        let key = NSString(string: rootPath)

        if let workspace = all.object(forKey: key) {
            return workspace
        }
        let workspace = MBWorkspace(rootPath: rootPath)
        all.setObject(workspace, forKey: key)
        return workspace
    }

    deinit {
        configFileSource?.cancel()
        configFileHandler?.closeFile()
    }

    public init(rootPath: String) {
        self.rootPath = rootPath
        super.init()
    }

    private var configFileHandler: FileHandle?
    private var configFileSource: DispatchSourceFileSystemObject?

    public lazy var config: MBConfig = self.reloadConfig()

    @discardableResult
    open func reloadConfig() -> MBConfig {
        let configDir = self.configDir
        let path = configDir.appending(pathComponent:"config.json")
        let config: MBConfig = MBConfig.load(fromFile: path)
        config.workspace = self
        self.config = config
        return config
    }

    public lazy var userSetting: MBSetting = self.readSetting()

    public func readSetting() -> MBSetting {
        let path = self.rootPath.appending(pathComponent: ".mboxconfig")
        return MBSetting.load(fromFile: path, name: "Workspace Setting")
    }

    dynamic
    open var plugins: [String: [MBSetting.PluginDescriptor]] {
        var result = [String: [MBSetting.PluginDescriptor]]()
        userSetting.plugins?.forEach { (name, desc) in
            var v = result[name] ?? []
            v.append(desc)
            result[name] = v
        }
        self.config.currentFeature.plugins.forEach { (name, descs) in
            var v = result[name] ?? []
            v.append(contentsOf: descs)
            result[name] = v
        }
        return result
    }

    /// Key must be lowercase, eg: { "ios": ["MBoxCocoapods"] }
    open class var pluginGroups: [String: [String]] {
        var v = [String: [String]]()
        for module in MBPluginManager.shared.allModules {
            for group in module.groups {
                let group = group.lowercased()
                var modules = v[group]
                if modules != nil {
                    modules!.append(module.name)
                } else {
                    modules = [module.name]
                }
                v[group] = modules
            }
        }
        return v
    }

    public lazy var logDirectory: String? = self.configDir.appending(pathComponent:"logs")
    
    // MARK: - class methods
    public static func searchRootPath(_ path: String) -> String? {
        var path = path
        while path.lengthOfBytes(using: .utf8) > 0 && path != "/" {
            if path.appending(pathComponent:".mbox").isExists {
                if path.realpath == FileManager.home.realpath {
                    return nil
                }
                return path
            }
            path = path.deletingLastPathComponent
        }
        return nil
    }

    @discardableResult
    open class func create(_ path: String, plugins: [String], uid: String?) throws -> MBWorkspace {
        return try UI.section("Create MBox configuration file") {
            let fm = FileManager.default
            let configDir = path.appending(pathComponent: ".mbox")
            UI.log(verbose: "Init workspace at `\(path)`")
            if !configDir.isExists {
                try UI.log(verbose: "Create directory `.mbox`") {
                    try fm.createDirectory(atPath: configDir, withIntermediateDirectories: true, attributes: nil)
                }
            }
            let workspace = MBWorkspace(rootPath: path)
            UI.log(verbose: "Save `\(workspace.config.filePath!.relativePath(from: workspace.rootPath))`") {
                if let uid = uid {
                    workspace.config.uid = uid
                }
                workspace.config.save()
            }

            var info = "Save `\(workspace.userSetting.filePath!.relativePath(from: workspace.rootPath))`"
            let plugins = plugins.sorted()
            if plugins.isEmpty {
                info.append(" without any plugins.")
            } else {
                info.append(" with plugins:")
            }
            UI.log(verbose: info, items: plugins) {
                workspace.userSetting.plugins = Dictionary(plugins.map { ($0, MBSetting.PluginDescriptor()) })
                workspace.userSetting.save()
            }

            try UI.log(verbose: "Create Git Configuration") {
                try workspace.setupGitConfig()
            }
            return workspace
        }
    }

    // MARK: - Environment
    dynamic
    public func setupEnvironment() throws {
        try self.updateSymlink()
    }

    dynamic
    public var pathsToLink: [String: String] {
        var v = [String: String]()
        for repo in self.config.currentFeature.repos {
            guard let workRepo = repo.workRepository else { continue }
            for path in workRepo.pathsToLink {
                v[path.lastPathComponent] = repo.name.appending(pathComponent: path)
            }
        }
        return v
    }

    private lazy var symlinkCachePath: String = self.configDir.appending(pathComponent: "symlinks.txt")

    private func currentSymlinks() -> [String: String] {
        var v = [String: String]()
        guard self.symlinkCachePath.isExists,
              let data = try? String(contentsOfFile: self.symlinkCachePath) else {
            return v
        }
        for name in data.lines() {
            if name.isEmpty || name == "." { continue }
            let path = self.rootPath.appending(pathComponent: name)
            if path.isExists {
                if path.isSymlink,
                   let target = try? FileManager.default.destinationOfSymbolicLink(atPath: path) {
                    v[name] = target
                } else {
                    v[name] = ""
                }
            }
        }
        return v
    }

    public func symlinksToUpdate() -> (all: [String: String], deleted: [String: String], new: [String: String]) {
        let toLinks = Dictionary(self.pathsToLink.map { (self.relativePath($0), $1) })
        let curLinks = currentSymlinks()

        let deleted = curLinks.filter { (name, target) in
            return toLinks[name] != target
        }

        let new = toLinks.filter { (name, target) in
            if curLinks[name] == target {
                return false
            }
            let targetPath: String
            if target.hasPrefix("/") {
                targetPath = target
            } else {
                targetPath = self.rootPath
                    .appending(pathComponent: name)
                    .deletingLastPathComponent
                    .appending(pathComponent: target)
            }
            return targetPath.cleanPath.isExists
        }

        return (all: toLinks, deleted: deleted, new: new)
    }

    public func updateSymlink() throws {
        let symlinks = symlinksToUpdate()
        let all = symlinks.all
        let deleted = symlinks.deleted
        let new = symlinks.new

        if deleted.isEmpty && new.isEmpty { return }

        try UI.log(verbose: "Update symbol links") {
            for (name, target) in deleted.sorted(by: \.key) {
                if name.isEmpty || name == "." { continue }
                let symbolPath = self.rootPath.appending(pathComponent: name)
                try UI.log(verbose: "Remove `\(name)` -> `\(target)`") {
                    try FileManager.default.removeItem(atPath: symbolPath)
                }
            }
            for (name, target) in new.sorted(by: \.key) {
                if name.isEmpty || name == "." { continue }
                let symbolPath = self.rootPath.appending(pathComponent: name)
                try UI.log(verbose: "Link `\(name)` -> `\(target)`") {
                    try? FileManager.default.removeItem(atPath: symbolPath)
                    let dir = symbolPath.deletingLastPathComponent
                    if !dir.isExists {
                        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
                    }
                    try FileManager.default.createSymbolicLink(atPath: symbolPath, withDestinationPath: target)
                }
            }
            try all.keys.sorted().joined(separator: "\n").write(toFile: self.symlinkCachePath, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - Git
    open lazy var gitConfigPath: String = self.configDir.appending(pathComponent: "git.config")

    open func gitConfig(for key: String) throws -> String? {
        return try UI.log(verbose: "Get git workspace config: \(key):") {
            return try GitHelper.getConfig(for: key, path: self.gitConfigPath)
        }
    }

    open func setGitConfig(_ value: String, for key: String) throws {
        try UI.log(verbose: "Set git workspace config: \(key): \(value)") {
            try GitHelper.setConfig(key: key, value: value, path: self.gitConfigPath)
        }
    }

    open func removeGitConfig(for key: String) throws {
        try UI.log(verbose: "Remove git workspace config: \(key)") {
            try GitHelper.removeConfig(key: key, path: self.gitConfigPath)
        }
    }

    dynamic
    open func setupGitConfig() throws {
        try self.setGitConfig("current", for: "push.default")
        try self.setupGitHooks(enable: true)
    }

    open func gitHooks() throws -> String? {
        return try self.gitConfig(for: "core.hooksPath")
    }

    open func setupGitHooks(enable: Bool) throws {
        if enable {
            if let hookPath = MBWorkspace.pluginPackage?.resoucePath(for: "gitHookManager") {
                try self.setGitConfig(hookPath, for: "core.hooksPath")
            }
        } else {
            try self.removeGitConfig(for: "core.hooksPath")
        }
    }

    // MARK: - workspace file
    dynamic
    open func workspaceIndex() -> [String: [(name: String, path: String)]] {
        return [:]
    }

    dynamic
    open func updateIndexFile(_ index: [String: [(name: String, path: String)]]) throws {

    }
}

public var Workspace: MBWorkspace { return MBProcess.shared.workspace! }
