//
//  MBWorkspaceCommander.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/6/6.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

var MBWorkspaceCommanderShowStatus: UInt8 = 0
var MBWorkspaceCommanderRequireSetupEnvironment: UInt8 = 0
var MBWorkspaceCommanderLockConfig: UInt8 = 0
var MBWorkspaceCommanderUpdateWorkspaceFile: UInt8 = 0
extension MBCommander {
    public class var workspace: MBWorkspace? {
        if let workspace = MBProcess.shared.workspace {
            return workspace
        }
        if let root = MBWorkspace.searchRootPath(FileManager.pwd) {
            return MBWorkspace(rootPath: root)
        }
        return nil
    }

    public class var config: MBConfig? {
        return self.workspace?.config
    }

    @_dynamicReplacement(for: autocompletionRedirect)
    public class var workspace_autocompletionRedirect: String {
        let string = self.autocompletionRedirect
        guard let workspace = self.workspace else { return string }
        return string + "@" + workspace.rootPath
    }

    public var workspace: MBWorkspace {
        return Workspace
    }

    public var config: MBConfig {
        return self.workspace.config
    }

    public var shouldLockConfig: Bool {
        set {
            associateObject(base: self, key: &MBWorkspaceCommanderLockConfig, value: newValue)
        }
        get {
            return associatedObject(base: self, key: &MBWorkspaceCommanderLockConfig, defaultValue: false)
        }
    }

    @_dynamicReplacement(for: performRun())
    public func workspacePerformRun() throws {
        try? self.runPreHook()
        defer {
            try? self.runPostHook()
        }
        guard self.shouldLockConfig else {
            try self.performRun()
            return
        }
        guard self.config.lock() else {
            throw RuntimeError("Another process is in progress!\nYou could remove the lock file: \(self.config.lockFilePath)")
        }
        defer {
            self.config.unlock()
        }
        trapSignal(.all) { _ in
            MBProcess.shared.workspace?.config.unlock(force: true)
        }
        try self.performRun()
    }

    public var currentRepo: MBConfig.Repo? {
        guard FileManager.pwd.hasPrefix(workspace.rootPath) else { return nil }
        let path = FileManager.pwd.deletePrefix(workspace.rootPath + "/")
        let name: String
        if let index = path.firstIndex(of: "/") {
            name = String(path[..<index])
        } else {
            name = path
        }
        return self.config.currentFeature.findRepo(name: name, searchPackageName: false).first
    }

    @_dynamicReplacement(for: setup())
    public func workspaceSetup() throws {
        try self.setup()
        if let workspace = MBProcess.shared.workspace,
           workspace.rootPath != FileManager.pwd,
           MBProcess.shared.showRootPath {
            UI.log(info: "[\(workspace.rootPath)]\n", pip: .ERR)
        }
        MBProcess.shared.showRootPath = false
    }

    public var showStatusAtFinish: [String]? {
        set {
            associateObject(base: self, key: &MBWorkspaceCommanderShowStatus, value: newValue)
        }
        get {
            return associatedObject(base: self, key: &MBWorkspaceCommanderShowStatus, defaultValue: nil)
        }
    }

    func performShowStatus() throws {
        try UI.section("Show Status") {
            let args = (self.showStatusAtFinish ?? []).flatMap { ["--only", $0] }
            try self.invoke(Status.self, argv: ArgumentParser(arguments: args))
        }
    }

    public var requireSetupEnvironment: Bool {
        set {
            associateObject(base: self, key: &MBWorkspaceCommanderRequireSetupEnvironment, value: newValue)
        }
        get {
            return associatedObject(base: self, key: &MBWorkspaceCommanderRequireSetupEnvironment, defaultValue: self.shouldLockConfig)
        }
    }

    func runSetupEnvironment(force: Bool = false) throws {
        if !self.requireSetupEnvironment && !force { return }
        try UI.log(verbose: "Setup Workspace Environment") {
            try self.workspace.setupEnvironment()
        }
    }

    @objc dynamic
    open func runPreHook() throws {
        try runSetupEnvironment()
        try runHookScript(preHook: true)
    }

    @objc dynamic
    open func runPostHook() throws {
        try runSetupEnvironment()
        if self.shouldUpdateWorkspaceFile {
            try self.workspace.updateIndexFile(self.workspace.workspaceIndex())
        }
        try runHookScript(preHook: false)
        if self.showStatusAtFinish != nil {
            try self.performShowStatus()
        }
    }

    @objc dynamic
    open func setupHookCMD(_ cmd: MBCMD, preHook: Bool) {

    }

    public func runHookScript(preHook: Bool) throws {
        guard let workspace = MBProcess.shared.workspace else {
            return
        }
        let hookDir = workspace.hookFileDir
        let hookFileName = preHook ? type(of: self).preScriptFileName : type(of: self).postScriptFileName
        let scriptPath = hookDir.appending(pathComponent: hookFileName)
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            return
        }
        UI.section("Run `\(hookFileName)` hook script") {
            let cmd = MBCMD()
            cmd.showOutput = true
            self.setupHookCMD(cmd, preHook: preHook)
            if !cmd.exec(scriptPath) {
                UI.log(warn: "Run `\(hookFileName)` hook script failed! ")
            }
        }
    }

    public var shouldUpdateWorkspaceFile: Bool {
        set {
            associateObject(base: self, key: &MBWorkspaceCommanderUpdateWorkspaceFile, value: newValue)
        }
        get {
            return associatedObject(base: self, key: &MBWorkspaceCommanderUpdateWorkspaceFile, defaultValue: self.shouldLockConfig)
        }
    }
}
