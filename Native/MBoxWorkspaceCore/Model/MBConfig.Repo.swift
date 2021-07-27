//
//  MBConfig.Repo.swift
//  MBoxCore
//
//  Created by Whirlwind on 2018/8/29.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBConfig {
    @objc(MBConfigRepo)
    public class Repo: MBCodableObject {
        public convenience init(feature: MBConfig.Feature) {
            self.init()
            self.feature = feature
        }

        public convenience init(path: String, name: String? = nil, feature: MBConfig.Feature) {
            self.init()
            self.feature = feature
            if let name = name {
                self.resolveName(name)
                self.path = path
            } else {
                self.resolveName(path: path)
            }
        }

        public convenience init?(url: String, feature: MBConfig.Feature) {
            guard let gitURL = MBGitURL(url) else {
                return nil
            }
            self.init()
            self.feature = feature
            self.resolveName(gitURL: gitURL)
        }

        public convenience init(name: String, feature: MBConfig.Feature) {
            self.init()
            self.feature = feature
            self.resolveName(name)
        }

        public override func bindProperties() {
            super.bindProperties()
            if self.url == nil || self.url?.isEmpty == true, !self.name.isEmpty {
                self.url = self.workRepository?.url
            }
            var gitURL: MBGitURL? = nil
            if let url = self.url {
                gitURL = MBGitURL(url)
            }
            self.resolveName(path: self._path, gitURL: gitURL)
        }

        @Codable(key: "path")
        open var _path: String?
        open var path: String {
            get {
                return self.workspace.fullPath(_path ?? storePath)
            }
            set {
                if newValue == self.storePath {
                    _path = nil
                } else {
                    _path = self.workspace.relativePath(newValue)
                }
            }
        }

        open var workingPath: String {
            return self.workspace.rootPath.appending(pathComponent: name)
        }

        open var storePath: String {
            return self.storePath(for: fullName)
        }

        private func storePath(for name: String) -> String {
            return self.workspace.repoStoreDir.appending(pathComponent:name)
        }

        open weak var feature: MBConfig.Feature!
        open var workspace: MBWorkspace = UI.workspace!

        open var config: MBConfig {
            return workspace.config
        }

        // MARK: - Repository
        private var _originRepository: MBStoreRepo?
        open var originRepository: MBStoreRepo? {
            set {
                _originRepository = newValue
            }
            get {
                if _originRepository == nil {
                    reloadOriginRepository()
                }
                return _originRepository
            }
        }

        @discardableResult
        open func reloadOriginRepository() -> MBStoreRepo? {
            _originRepository = MBStoreRepo(path: self.path)
            return _originRepository
        }

        open func createOriginRepository() throws {
            _originRepository = try self.workspace.create(name: self.fullName)
        }

        private var _workRepository: MBWorkRepo?
        open var workRepository: MBWorkRepo? {
            set {
                _workRepository = newValue
            }
            get {
                if _workRepository == nil {
                    reloadWorkRepository()
                }
                return _workRepository
            }
        }

        @discardableResult
        open func reloadWorkRepository() -> MBWorkRepo? {
            _workRepository = MBWorkRepo(model: self)
            return _workRepository
        }

        @Codable
        public var url: String?

        @Codable
        public var name: String

        @Codable
        public var owner: String?

        @Codable(getterTransform: { (value, instance) in
            if let value = value as? String { return value }
            let obj = instance as! MBConfig.Repo
            return obj.name
        })
        public var fullName: String

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

        @Codable(key: "feature_branch")
        private var _featureBranch: String?
        public var featureBranch: String? {
            get {
                if self.feature.free { return nil }
                return _featureBranch ?? self.feature.branchName
            }
            set {
                _featureBranch = newValue
            }
        }
        public func isInFeatureBranch(_ git: GitPointer) -> Bool {
            if self.feature.free { return true }
            guard git.isBranch else { return false }
            return git.value == self.featureBranch
        }

        public func resolveName(_ fullName: String? = nil, path: String? = nil, gitURL: MBGitURL? = nil) {
            var fullName: String? = fullName
            var name: String?
            var owner: String?
            var gitURL = gitURL
            if let path = path {
                fullName ?= path.lastPathComponent
                if gitURL == nil, let url = try? GitHelper(path: path).url, let gurl = MBGitURL(url) {
                    gitURL = gurl
                }
            }
            if let gitURL = gitURL {
                self.url = gitURL.url
                fullName ?= gitURL.project + "@" + gitURL.group
            }
            if let fullName = fullName, let index = fullName.firstIndex(of: "@") {
                name = String(fullName[..<index])
                owner = String(fullName[fullName.index(after: index)...])
            } else {
                name = fullName
                owner = nil
            }
            var fullNames = [String]()
            if let fullName = fullName {
                fullNames << fullName
            }
            fullNames << self.name
            if let name = name {
                fullNames << name
            }
            for n in fullNames {
                if n.isEmpty { continue }
                let path = self.storePath(for: n)
                if path.isExists {
                    self.fullName = n
                    break
                }
            }
            if let name = name, self.name.isEmpty {
                self.name = name
            }
            if let owner = owner {
                self.owner ?= owner
            }
            if let path = path {
                self.path = path
            }
        }

        public override var description: String {
            return self.name
        }

        public func clone(recurseSubmodules: Bool = false) throws {
            let git = try GitHelper(path: self.path, url: self.url)
            try git.clone(checkout: false, recurseSubmodules: recurseSubmodules)
            self.originRepository = MBStoreRepo(path: self.path)
        }

        // MARK: - Package Name
        public var additionalPackageNames: [String] = []

        dynamic
        open func fetchPackageNames() -> [String] {
            var names = [self.name]
            let name = path.lastPathComponent
            if let index = name.lastIndex(of: "@") {
                names << String(name[..<index])
            } else {
                names << name
            }
            if let url = self.url, let gitURL = MBGitURL(url) {
                names << gitURL.project
            }
            return names
        }

        open lazy var packageNames: [String] = {
            var names = self.fetchPackageNames()
            names.append(contentsOf: additionalPackageNames)
            if let workRepo = self.workRepository {
                names.append(contentsOf: workRepo.packageNames)
            }
            return names.withoutDuplicates()
        }()

        open func isName(_ name: String, owner: String? = nil, searchPackageName: Bool = true) -> Bool {
            if let owner = owner, owner.lowercased() != self.owner?.lowercased() {
                return false
            }
            let names: [String]
            if !searchPackageName {
                names = self.fetchPackageNames()
            } else {
                names = self.packageNames
            }
            let name = name.lowercased()
            for packageName in names {
                if packageName.lowercased() == name {
                    return true
                }
            }
            return false
        }
    }
}

extension MBConfig.Repo: NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        let repo = MBConfig.Repo(feature: self.feature!)
        repo.dictionary = self.dictionary
        return repo
    }
    public static func copy(with repo: MBConfig.Repo, baseGitPointer: GitPointer?, targetBranch: String?) -> MBConfig.Repo {
        let r = repo.copy() as! MBConfig.Repo
        r.lastGitPointer = nil
        if let baseGitPointer = baseGitPointer {
            r.baseGitPointer = baseGitPointer
        } else {
            r.baseGitPointer = nil
        }
        r.targetBranch = targetBranch
        return r
    }
}

extension MBConfig.Repo {
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MBConfig.Repo else {
            return false
        }
        return self.url == other.url || self.fullName == other.fullName || self.name == other.name
    }
    public static func == (lhs: MBConfig.Repo, rhs: MBConfig.Repo) -> Bool {
        return lhs.isEqual(rhs)
    }
}

extension MBConfig.Repo {

    // MARK: - Work
    open func work(_ head: GitPointer? = nil) throws {
        try UI.section("Make repository work") {
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
                try git.pruneWorkTree(name)
                let targetHEAD: String?
                if let head = head, !head.isCommit {
                    targetHEAD = head.value
                } else {
                    targetHEAD = nil
                }
                try git.addWorkTree(name: name, path: workPath, head: targetHEAD)
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
            if let workRepo = self.workRepository {
                try? workRepo.git?.checkout()
                try workRepo.includeGitConfig()
            }
        }
    }

    // MARK: - Import
    open func `import`(mode: MBStoreRepo.Mode) throws {
        try UI.log(verbose: "Import `\(self.path)`") {
            guard let git = self.originRepository?.git else { throw RuntimeError() }
            let workDir = git.path!
            let gitStatus = try mode == .worktree ? nil : git.currentDescribe()
            try UI.log(verbose: "Import to `\(Workspace.relativePath(self.storePath))`") {
                try self.originRepository?.import(to: self.storePath, mode: mode)
            }
            self.path = self.originRepository!.path
            try? FileManager.default.removeItem(atPath: workingPath)
            try self.work(gitStatus)
            if mode == .move || mode == .copy {
                try UI.log(verbose: "Copy workcopy into `\(Workspace.relativePath(workingPath))`") {
                    let cmd = RSyncCMD()
                    guard cmd.exec(sourceDir: workDir, targetDir: workingPath, delete: true, ignoreExisting: false, progress: true, exclude: [".git"]) else {
                        throw RuntimeError("Rsync workDir failed!")
                    }
                }
            }
            if mode == .move {
                UI.log(verbose: "Remove `\(workDir)`") {
                    try? FileManager.default.removeItem(atPath: workDir)
                }
            }
        }
    }
}
