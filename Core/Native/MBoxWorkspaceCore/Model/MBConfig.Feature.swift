//
//  MBConfig.Feature.swift
//  MBoxCore
//
//  Created by Whirlwind on 2018/8/28.
//  Copyright © 2018 Bytedance. All rights reserved.
//

import Cocoa
import MBoxCore
import MBoxGit

extension MBConfig {
    public class Feature: MBCodableObject {

        public override var description: String {
            return self.name
        }

        public static let FreeMode = "FreeMode"

        open weak var config: MBConfig!

        public var name: String {
            set { _name = newValue }
            get { return free ? MBConfig.Feature.FreeMode : _name! }
        }

        public var free: Bool {
            return (self._name?.count ?? 0) == 0
        }

        public var stashName: String {
            return "MBox-\(stashHash)"
        }
        public func regenerateStashHash() {
            self.stashHash = MBConfig.Feature.generateStashHash()
        }
        public static func generateStashHash() -> String {
            return UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }

        public var branchName: String {
            return free ? "" : "\(branchPrefix)\(name)"
        }

        private var _mergeRequest: [[String: Any]]?
        public var mergeRequest: [[String: Any]]? {
            set {
                let newValue = newValue?.count == 0 ? nil : newValue
                _mergeRequest = newValue
            }
            get {
                return _mergeRequest
            }
        }

        // MARK: - API
        public var isCurrent: Bool {
            return config.currentFeatureName == name
        }

        public var couldDeleted: Bool {
            if free { return false }
            if isCurrent { return false }
            return true
        }
        
        public required init() {
            super.init()
            _ = self.uid
        }

        public required init(dictionary: [String: Any]) {
            super.init(dictionary: dictionary)
            _ = self.uid
        }
        
        convenience init(name: String, branchPrefix: String? = nil) {
            self.init()
            self.name = name
            self.branchPrefix = branchPrefix ?? MBSetting.merged.workspace.branchPrefix ?? Self.BranchPrefix
            self.stashHash = Self.generateStashHash()
        }

        open func eachRepos(_ repos: [MBConfig.Repo], block: @escaping (MBConfig.Repo) throws -> Void ) rethrows {
            try repos.forEach { repo in
                let code = {
                    try block(repo)
                }
                if UI.indents.count == 0 {
                    try UI.section("[\(repo)]", block: code)
                } else {
                    try UI.log(verbose: "[\(repo)]", block: code)
                }
            }
        }

        open func eachRepos(skipNonExists: Bool = true, block: @escaping (MBConfig.Repo) throws -> Void ) rethrows {
            try repos.forEach { repo in
                let code = {
                    if skipNonExists && repo.workRepository == nil {
                        UI.log(verbose: "Repo `\(repo)` not exists!")
                        return
                    }
                    try block(repo)
                }
                if UI.indents.count == 0 {
                    try UI.section("[\(repo)]", block: code)
                } else {
                    try UI.log(verbose: "[\(repo)]", block: code)
                }
            }
        }

        // MARK: - JSON
        @Codable(key: "name")
        private var _name: String?

        public var isNew: Bool? = false

        @Codable(setterTransform: { (prefix, instance) -> String in
            return prefix.count != 0 && !prefix.hasSuffix("/") ? "\(prefix)/" : prefix })
        open var branchPrefix: String
        public static let BranchPrefix = "feature/"

        @Codable
        public var uid: String = UUID().uuidString.replacingOccurrences(of: "-", with: "")

        public var stashHash: String {
            set { self.dictionary["stash_hash"] = newValue }
            get {
                var hash = self.dictionary["stash_hash"] as? String
                if hash == nil {
                    hash = MBConfig.Feature.generateStashHash()
                    self.dictionary["stash_hash"] = hash
                }
                return hash!
            }
        }

        @Codable(key: "repos", getterTransform: { (repos, instance) -> [MBConfig.Repo] in
            guard let self = instance as? Feature else { return [] }
            if let value = try? [MBConfig.Repo].load(fromObject: repos as Any) {
                return value.then { $0.feature = self }
            }
            return []
        })
        public var repos: [MBConfig.Repo] {
            didSet {
                self.reposDidChanged()
            }
        }

        dynamic
        public func reposDidChanged() {
            for repo in self.repos {
                repo.feature = self
            }
        }

        public var workRepos: [MBWorkRepo] {
            return repos.compactMap(\.workRepository)
        }

        dynamic
        public override func prepare(dictionary: [String : Any]) -> [String : Any] {
            return super.prepare(dictionary: dictionary)
        }

        dynamic
        public func plugins(for repo: MBConfig.Repo) -> [String: MBSetting.PluginDescriptor] {
            return repo.workRepository?.setting.plugins ?? [:]
        }

        public var plugins: [String: [MBSetting.PluginDescriptor]] {
            var result = [String: [MBSetting.PluginDescriptor]]()
            for repo in self.repos {
                let plugins = self.plugins(for: repo)
                for (name, desc) in plugins {
                    var v = result[name] ?? []
                    v.append(desc)
                    result[name] = v
                }
            }
            return result
        }


    }
}

extension MBConfig.Feature {
    public func copy(with name: String, branchPrefix: String?) -> Self {
        let newFeature: MBConfig.Feature = Self.init(dictionary: self.dictionary)
        newFeature.name = name
        newFeature.branchPrefix = branchPrefix ?? MBSetting.merged.workspace.branchPrefix ?? Self.BranchPrefix
        newFeature.stashHash = Self.generateStashHash()
        return newFeature as! Self
    }
}
