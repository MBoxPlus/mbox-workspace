//
//  MBConfig.Feature.swift
//  MBoxCore
//
//  Created by Whirlwind on 2018/8/28.
//  Copyright © 2018年 Bytedance. All rights reserved.
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

        convenience init(name: String, branchPrefix: String? = nil) {
            self.init()
            self.name = name
            self.branchPrefix = branchPrefix ?? Self.BranchPrefix
            self.stashHash = Self.generateStashHash()
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
        // feature 导出口令
    //    public class func generatePassport(_ json: String) -> String? {
    //        guard let value = json.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
    //            return nil
    //            }
    //        return "\(MBoxPluginPath.Feature.Import)?json=\(value)"
    //    }

        dynamic
        open var exportKeys: [String] {
            return [self.__name.key!, self._branchPrefix.key!, self._repos.key!]
        }

        dynamic
        open var exportHash: [String: Any] {
            let keys = self.exportKeys
            return self.dictionary.filter { (key, value) -> Bool in
                return keys.contains(key) && !(value is NSNull)
            }
        }

        public func export() throws -> String {
            return try exportHash.toString(coder: .json, sortedKeys: true, prettyPrinted: false)
        }

        // MARK: - JSON
        @Codable(key: "name")
        private var _name: String?

        @Codable
        public var isNew: Bool? = false

        @Codable(setterTransform: { (prefix, instance) -> String in
            return prefix.count != 0 && !prefix.hasSuffix("/") ? "\(prefix)/" : prefix })
        open var branchPrefix: String
        public static let BranchPrefix = "feature/"

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

        @Codable(key: "repos")
        public var repos: [MBConfig.Repo] = [] {
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
            var dictionary = super.prepare(dictionary: dictionary)
            if let repos = dictionary["repos"] {
                dictionary["repos"] = try? [MBConfig.Repo].load(fromObject: repos).then { $0.feature = self }
            }
            return dictionary
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
        newFeature.branchPrefix = branchPrefix ?? Self.BranchPrefix
        newFeature.stashHash = Self.generateStashHash()
        return newFeature as! Self
    }
}
