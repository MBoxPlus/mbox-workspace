//
//  MBWorkspace+Repo.swift
//  MBoxWorkspaceCore
//
//  Created by Whirlwind on 2021/3/19.
//  Copyright © 2021 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBWorkspace {

    public var repos: [MBConfig.Repo] {
        return config.currentFeature.repos
    }

    public class func eachRepos<T>(_ repos: [T], title: String? = nil, block: @escaping (T) throws -> Void ) throws {
        try repos.forEach { repo in
            let code = {
                try block(repo)
            }
            var msg = "[\(repo)]"
            if let title = title { msg.append(" \(title)") }
            try UI.allowAsyncExec(title: msg, block: code)
        }
        try UI.wait()
    }

    // MARK: - Store Repos
    public var worktreeCacheDir: String {
        return configDir.appending(pathComponent: "repo_worktrees")
    }

    public var repoStoreDir: String {
        return configDir.appending(pathComponent: "repos")
    }

    public func createStoreRepoDir() throws {
        try FileManager.default.createDirectory(atPath: repoStoreDir,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
    }

    public var allRepos: [MBStoreRepo] {
        let dirs = repoStoreDir.subDirectories + self.config.features.flatMap { $0.value.repos.map { $0.path } }
        return dirs.withoutDuplicates().compactMap { MBStoreRepo(path: $0) }
    }

    public func findAllRepo(url: String) -> MBStoreRepo? {
        return self.findAllRepo(url: url, in: allRepos)
    }

    public func findAllRepo(url: String, in all: [MBStoreRepo]) -> MBStoreRepo? {
        return all.first { $0.url?.lowercased() == url.lowercased() }
    }

    public func findAllRepo(name: String, owner: String? = nil) -> MBStoreRepo? {
        var owner = owner
        if owner == nil, let index = name.firstIndex(of: "@") {
            owner = String(name[name.index(after: index)...])
        }
        return allRepos.first { $0.isName(name, owner: owner) }
    }

    // MARK: Create
    public func create(name: String) throws -> MBStoreRepo {
        if let repo = findAllRepo(name: name) { return repo }
        let repos = Set(config.features.values).flatMap(\.repos)
        let repoConfig = repos.first(where: { $0.name.lowercased() == name.lowercased() || $0.fullName.lowercased() == name.lowercased() }) ?? MBConfig.Repo(name: name, feature: config.currentFeature)
        if let repo = repoConfig.originRepository { return repo }
        let path = repoConfig.storePath
        return try UI.log(verbose: "Create repository at: `\(path)`") {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            let _ = try GitHelper.create(path: path)
            let repo = MBStoreRepo(path: path)!
            try repo.git!.setHEAD(.commit(repo.git!.currentCommit!))
            return repo
        }
    }

    // MARK: - Work Repos
    public var workRepos: [MBWorkRepo] {
        return config.currentFeature.workRepos
    }

    public func findWorkRepo(url: String) -> MBWorkRepo? {
        return workRepos.first { $0.url?.lowercased() == url.lowercased() }
    }

    public func findWorkRepo(name: String, owner: String? = nil) -> MBWorkRepo? {
        var owner = owner
        if owner == nil, let index = name.firstIndex(of: "@") {
            owner = String(name[name.index(after: index)...])
        }
        return workRepos.first { $0.isName(name, owner: owner) }
    }

    public func eachWorkRepos(block: @escaping (MBWorkRepo) throws -> Void ) throws {
        try Self.eachRepos(repos) { repo in
            guard let workRepo = repo.workRepository else {
                UI.log(verbose: "Repo `\(repo)` not exists!")
                return
            }
            try block(workRepo)
        }
    }

}
