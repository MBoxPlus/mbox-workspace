//
//  MBWorkspace.swift
//  MBoxCore
//
//  Created by Whirlwind on 2018/8/28.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

open class MBWorkspace: NSObject {

    public static var all = NSMapTable<NSString, MBWorkspace>.strongToWeakObjects()

    public var verbose = false
    public var silent = false

    public lazy var name: String? = {
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
    
    /// hook script 文件目录
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
//        self.postNotification(NTF.create)
//        if rootPath != nil {
//            weak var weakWorskspace = workspace
//            #if !DEBUG
//            NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: OperationQueue.main) { _ in
//                weakWorskspace?.gitReloadStatus(useCache: false)
//            }
//            #endif
//            NSApplication.wantsRefresh.addObserver(workspace, windowController: nil, workspace: workspace) { ntf in
//                ntf.workspace?.reloadConfig()
//                ntf.workspace?.gitReloadStatus(useCache: false)
//            }
//        }
        return workspace
    }

    deinit {
        configFileSource?.cancel()
        configFileHandler?.closeFile()
    }

    public init(rootPath: String) {
        self.rootPath = rootPath
        super.init()
        UI.workspace = self
    }

    private var configFileHandler: FileHandle?
    private var configFileSource: DispatchSourceFileSystemObject?

    public lazy var config: MBConfig = {
        guard let config = reloadConfig() else {
            var conf = MBConfig()
            conf.filePath = configDir.appending(pathComponent:"config.json")
            return conf
        }

        // Here we are monitoring the config file.
//        configFileHandler = FileHandle.init(forReadingAtPath: config.filePath!)
//        configFileSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: configFileHandler!.fileDescriptor, eventMask: .write, queue: .main)
//        if let fileSource = configFileSource {
//            fileSource.setEventHandler(handler: { [weak self] in
//                guard let self = self else { return }
//                self.reloadConfig()
//            })
//            fileSource.resume()
//        }

        return config
    }()

    @discardableResult
    open func reloadConfig() -> MBConfig? {
        let configDir = self.configDir
        let path = configDir.appending(pathComponent:"config.json")
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try "{}".write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
            } catch {
                UI.log(error: "Init Configuration file failed: `\(path)`")
            }
        }
        guard let config = MBConfig.load(fromFile: path) else { return nil }
        config.workspace = self
        self.config = config
        return config
    }

    public lazy var userSetting: MBSetting = self.readSetting()

    public func readSetting() -> MBSetting {
        let path = self.rootPath.appending(pathComponent: ".mboxconfig")
        return MBSetting.load(fromFile: path, source: "Workspace Setting")
    }

    dynamic
    open var plugins: [String: [MBSetting.PluginDescriptor]] {
        var result = [getModuleName(forClass: type(of: self)):
                        [MBSetting.PluginDescriptor(requiredBy: "Application")]]
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

    /// Key 必须是小写，例如：{ "ios": ["MBoxCocoapods"] }
    open class var pluginGroups: [String: [String]] {
        var v = [String: [String]]()
        for plugin in Array(MBPluginManager.shared.allPackages.values) {
            guard let groups = plugin.groups else { continue }
            for group in groups {
                let group = group.lowercased()
                var plugins = v[group]
                if plugins != nil {
                    plugins!.append(plugin.name)
                } else {
                    plugins = [plugin.name]
                }
                v[group] = plugins
            }
        }
        return v
    }

    public lazy var logDirectory: String? = self.configDir.appending(pathComponent:"logs")

//    open func repoPerform(_ title: String, notification: String? = nil, _ block: @escaping (MBSession, MBConfig.Repo) -> Bool) {
//        let repos = self.config.currentFeature.repos
//        UI.section("Workspace \(title)", block: {
//            for repo in repos {
//                UI.newSection("[\(repo)]") { session2 in
//                    session2.status = block(session2, repo)
//                }
//            }
//        }, waitCallback: { _ in
//            if let notification = notification {
//                self.postNotification(notification)
//            }
//        })
//    }
    
    // MARK: - class methods
    public static func searchRootPath(_ path: String) -> String? {
        var path = path
        while path.lengthOfBytes(using: .utf8) > 0 && path != "/" && path != FileManager.default.homeDirectoryForCurrentUser.path {
            if FileManager.default.fileExists(atPath: path.appending(pathComponent:".mbox")) {
                return path
            }
            path = path.deletingLastPathComponent
        }
        return nil
    }

    @discardableResult dynamic
    open class func create(_ path: String, plugins: [String]) throws -> MBWorkspace {
        return try UI.section("Create MBox configuration file") {
            let fm = FileManager.default
            let configDir = path.appending(pathComponent: ".mbox")
            if !configDir.isExists {
                try UI.log(verbose: "Create directory `.mbox`") {
                    try fm.createDirectory(atPath: configDir, withIntermediateDirectories: true, attributes: nil)
                }
            }
            let workspace = MBWorkspace(rootPath: path)
            UI.log(verbose: "Save `\(workspace.config.filePath!.relativePath(from: workspace.rootPath))`") {
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
                workspace.userSetting.plugins = Dictionary(uniqueKeysWithValues: plugins.map { ($0, MBSetting.PluginDescriptor()) })
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
        let toLinks = Dictionary(uniqueKeysWithValues: self.pathsToLink.map { (self.relativePath($0), $1) })
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

    open func setGitConfig(_ value: String, for key: String) throws {
        try GitHelper.setConfig(key: key, value: value, path: self.gitConfigPath)
    }

    dynamic
    open func setupGitConfig() throws {
        try self.setGitConfig("current", for: "push.default")
        if let hookPath = MBWorkspace.pluginPackage?.resoucePath(for: "gitHookManager") {
            try self.setGitConfig(hookPath, for: "core.hooksPath")
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

public var Workspace: MBWorkspace { return UI.workspace! }
