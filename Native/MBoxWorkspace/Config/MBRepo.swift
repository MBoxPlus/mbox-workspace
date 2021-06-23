//
//  MBRepo.swift
//  MBoxCore
//
//  Created by Whirlwind on 2018/8/29.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Cocoa
import MBoxCore
import MBoxGit

public class MBRepo: MBCodableObject, MBJSONProtocol {
    public convenience init(git: GitHelper, in workspace: MBWorkspace) {
        self.init()
        self.git = git
        self.url = git.url
        self.workspace = workspace
        self.path = git.path
    }

    public convenience init(path: String, in workspace: MBWorkspace) {
        self.init()
        self.workspace = workspace
        self.path = path
        self.url = self.git?.url
    }

    public convenience init(url: String, in workspace: MBWorkspace) {
        self.init()
        self.workspace = workspace
        self.url = url
    }

    public convenience init(name: String, in workspace: MBWorkspace) {
        self.init()
        self.workspace = workspace
        self.name = name
        self.fullName = name
    }

    public convenience init(_ workspace: MBWorkspace) {
        self.init()
        self.workspace = workspace
    }

    public static func copy(with repo: MBRepo, baseGitPointer: GitPointer?, targetBranch: String?) -> MBRepo {
        let r = repo.copy() as! MBRepo
        r.lastGitPointer = nil
        if let baseGitPointer = baseGitPointer {
            r.baseGitPointer = baseGitPointer
        } else {
            r.baseGitPointer = nil
        }
        r.targetBranch = targetBranch
        return r
    }

    open weak var workspace: MBWorkspace!
    open var config: MBConfig {
        return workspace.config
    }

    public override func bindProperties() {
        super.bindProperties()
    }

    @Codable(key: "url")
    private var _url: String?

    public var url: String? {
        set {
            if _url == newValue { return }
            _url = newValue
            self.resetInfo()
        }
        get {
            if _url?.isEmpty ?? true {
                var u = self.git?.url
                if u?.isEmpty ?? false { u = nil }
                _url = u
            }
            return _url
        }
    }

    @Codable(getterTransform: { (name, instance) -> String in
        if let name = name as? String, !name.isEmpty { return name }
        let `self` = instance as! MBRepo
        if self._path == nil && self._url == nil {
            return ""
        }
        if let project = self.gitURL?.project {
            return project
        }
        if let path = self._path?.lastPathComponent {
            return self.resolveName(path).name
        }
        return ""
    })
    public var name: String

    @Codable(getterTransform: { (owner, instance) -> String? in
        if let owner = owner as? String, !owner.isEmpty { return owner }
        let `self` = instance as! MBRepo
        if self._url == nil { return nil }
        if let group = self.gitURL?.group { return group }
        if let path = self._path?.lastPathComponent {
            return self.resolveName(path).owner
        }
        return nil
    })
    public var owner: String?

    @Codable(getterTransform: { (fullName, instance) -> String in
        if let fullName = fullName as? String, !fullName.isEmpty {
            return fullName
        }
        guard let self = instance as? MBRepo else {
            return ""
        }
        if let owner = self.owner {
            return "\(self.name)@\(owner)"
        } else {
            return self.name
        }
    })
    public var fullName: String!

    @Codable
    public var baseBranch: String?

    @Codable
    public var baseType: String?
    
    public var baseGitPointer: GitPointer? {
        get {
            if let baseBranch = self.baseBranch {
                if let baseType = self.baseType {
                    return GitPointer(type: baseType, value: baseBranch)
                }
                return GitPointer.unknown(baseBranch)
            }
            return targetGitPointer
        }
        set {
            self.baseBranch = newValue?.value
            self.baseType = newValue?.type
        }
    }

    @Codable
    public var targetBranch: String?

    public var targetGitPointer: GitPointer? {
        set {
            self.targetBranch = newValue?.value
        }
        get {
            if let targetBranch = self.targetBranch {
                return .branch(targetBranch)
            }
            return nil
        }
    }

    @Codable
    public var lastBranch: String?

    @Codable
    public var lastType: String?

    public var lastGitPointer: GitPointer? {
        get {
            if let lastBranch = self.lastBranch {
                return GitPointer(type: self.lastType ?? "branch", value: lastBranch)
            }
            return nil
        }
        set {
            self.lastBranch = newValue?.value
            self.lastType = newValue?.type
        }
    }

    open lazy var gitURL: MBGitURL? = {
        if let url = self.url {
            return MBGitURL(url)
        }
        return nil
    }()

    open var workingPath: String {
        return self.workspace.rootPath.appending(pathComponent: name)
    }
    open var cachePath: String {
        return self.config.dir!.appending(pathComponent:"repos").appending(pathComponent:fullName)
    }
    private var _path: String?
    open var path: String? {
        set {
            if _path == newValue { return }
            _path = newValue
            self.resetInfo()
            if self.gitURL == nil, let path = _path?.lastPathComponent {
                let info = resolveName(path)
                self.name = info.name
                self.owner = info.owner
            }
        }
        get {
            if let p = _path, p.isExists {
                return p
            }
            if workingPath.isExists {
                return workingPath
            }
            if cachePath.isExists {
                return cachePath
            }
            return nil
        }
    }

    open var isCache: Bool {
        return !cachePath.isSymlink && cachePath.isExists
    }

    open var isWorking: Bool {
        return workingPath.isExists
    }

    dynamic
    open func work() throws {
        if isWorking {
            UI.log(verbose: "Repo `\(name)` is working!")
            return
        }
        guard let path = self.path, path.isExists else {
            throw RuntimeError("Repo `\(name)` not exists!")
        }
        let message = "Move `\(path.relativePath(from: config.workspace.rootPath))` -> `\(workingPath.relativePath(from: config.workspace.rootPath))`"
        try UI.log(verbose: message) {
            try FileManager.default.moveItem(atPath: path, toPath: workingPath)
        }
        try FileManager.default.createSymbolicLink(atPath: cachePath, withDestinationPath: workingPath.relativePath(from: cachePath.deletingLastPathComponent))
        try self.resetGit()
        try self.includeGitConfig()
    }

    open func cache() throws {
        if !exists {
            UI.log(verbose: "Repo `\(name)` not exists.")
            return
        }
        if isWorking {
            let message = "Move `\(workingPath.relativePath(from: config.workspace.rootPath))` -> `\(cachePath.relativePath(from: config.workspace.rootPath))`"
            try UI.log(verbose: message) {
                if cachePath.isSymlink {
                    try FileManager.default.removeItem(atPath: cachePath)
                }
                try FileManager.default.moveItem(atPath: workingPath, toPath: cachePath)
            }
            try self.resetGit()
        } else {
            UI.log(verbose: "Repo `\(name)` is not in working.")
        }
        // Cache 中的仓库不应该指向任何分支，因此采用指向当前 Commit 的方案
        // 防止 Worktree 模式下，占用分支导致其他项目无法 Checkout
        try UI.log(verbose: "Checkout to HEAD commit") {
            guard let git = git else { return }
            if git.isUnborn {
                UI.log(verbose: "There is not any commits in the repo, skip.")
                return
            }
            guard let commit = git.currentCommit else {
                throw RuntimeError("Could not get git information.")
            }
            try checkout(.commit(commit))
        }
    }

    dynamic
    open var exists: Bool {
        return FileManager.default.fileExists(atPath: workingPath) ||
            FileManager.default.fileExists(atPath: cachePath)
    }

    open lazy var setting: MBSetting = {
        let path = self.path!.appending(pathComponent: ".mboxconfig")
        return MBSetting.load(fromFile: path) ?? MBSetting(path: path)
    }()

    private var gitLoaded = false
    public lazy var git: GitHelper? = {
        gitLoaded = true
        return try? GitHelper(path: self.path ?? self.cachePath, url: _url)
    }()

    public func includeGitConfig() throws {
        if !self.exists { return }
        guard let git = self.git else { return }
        try UI.log(verbose: "Inject workspace config file into `\(self.name)`") {
            var workspaceConfigPath = self.workspace.gitConfigPath
            if let repoConfigPath = git.configPath?.deletingLastPathComponent {
                workspaceConfigPath = workspaceConfigPath.relativePath(from: repoConfigPath)
            }
            try git.includeConfig(workspaceConfigPath)
        }
    }

    public func resolveName(_ fullName: String) -> (name: String, owner: String?) {
        if let index = fullName.firstIndex(of: "@") {
            let name = String(fullName[..<index])
            let owner = String(fullName[fullName.index(after: index)...])
            return (name, owner)
        }
        return (fullName, nil)
    }

    public func resetInfo() {
        if let url = self.url {
            self.name = ""
            self.owner = nil
            self.fullName = nil
            self.gitURL = MBGitURL(url)
        }
        if gitLoaded {
            try? resetGit()
        }
    }

    public func resetGit() throws {
        gitLoaded = true
        self.git = try GitHelper(path: self.path ?? self.cachePath, url: _url)
        if let url = self.git?.url {
            self.url = url
        }
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MBRepo else {
            return false
        }
        if self.url != nil || other.url != nil {
            return self.url == other.url
        }
        if self.fullName != nil || other.fullName != nil {
            return self.fullName == other.fullName
        }
        return self.name == other.name
    }

    public static func == (lhs: MBRepo, rhs: MBRepo) -> Bool {
        return lhs.isEqual(rhs)
    }

    public override var description: String {
        return self.name
    }

    open lazy var packageNames: [String] = self.resolvePackageNames().withoutDuplicates()

    open func isName(_ name: String) -> Bool {
        let name = name.lowercased()
        for packageName in self.packageNames {
            if packageName.lowercased() == name {
                return true
            }
        }
        return false
    }

    dynamic
    open func resolvePackageNames() -> [String] {
        var names = [self.name]
        if let path = self.path {
            let name = path.lastPathComponent
            if self.isCache, let index = name.lastIndex(of: "@") {
                names << String(name[..<index])
            } else {
                names << name
            }
        }
        if let url = self.gitURL {
            names << url.project
        }
        return names
    }
}

extension MBRepo: NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        let repo = MBRepo(self.workspace)
        repo.path = self.path
        repo.dictionary = self.dictionary
        return repo
    }
}
