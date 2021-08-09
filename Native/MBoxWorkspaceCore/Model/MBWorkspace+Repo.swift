//
//  MBWorkspace+Repo.swift
//  MBoxWorkspaceCore
//
//  Created by 詹迟晶 on 2021/3/19.
//  Copyright © 2021 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBWorkspace {

    open var repos: [MBConfig.Repo] {
        return config.currentFeature.repos
    }

    // MARK: - Store Repos
    open var worktreeCacheDir: String {
        return configDir.appending(pathComponent: "repo_worktrees")
    }

    open var repoStoreDir: String {
        return configDir.appending(pathComponent: "repos")
    }

    open func createStoreRepoDir() throws {
        try FileManager.default.createDirectory(atPath: repoStoreDir,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
    }

    open var allRepos: [MBStoreRepo] {
        return repoStoreDir.subDirectories.withoutDuplicates().compactMap { MBStoreRepo(path: $0) }
    }

    open func findAllRepo(url: String) -> MBStoreRepo? {
        return allRepos.first { $0.url?.lowercased() == url.lowercased() }
    }

    open func findAllRepo(name: String, owner: String? = nil) -> MBStoreRepo? {
        var owner = owner
        if owner == nil, let index = name.firstIndex(of: "@") {
            owner = String(name[name.index(after: index)...])
        }
        return allRepos.first { $0.isName(name, owner: owner) }
    }

    // MARK: Create
    open func create(name: String) throws -> MBStoreRepo {
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
    open var workRepos: [MBWorkRepo] {
        return config.currentFeature.workRepos
    }

    open func findWorkRepo(url: String) -> MBWorkRepo? {
        return workRepos.first { $0.url?.lowercased() == url.lowercased() }
    }

    open func findWorkRepo(name: String, owner: String? = nil) -> MBWorkRepo? {
        var owner = owner
        if owner == nil, let index = name.firstIndex(of: "@") {
            owner = String(name[name.index(after: index)...])
        }
        return workRepos.first { $0.isName(name, owner: owner) }
    }

    open func eachWorkRepos(block: @escaping (MBWorkRepo) throws -> Void ) rethrows {
        try repos.forEach { repo in
            let code = {
                guard let workRepo = repo.workRepository else {
                    UI.log(verbose: "Repo `\(repo)` not exists!")
                    return
                }
                try block(workRepo)
            }
            if UI.indents.count == 0 {
                try UI.section("[\(repo)]", block: code)
            } else {
                try UI.log(verbose: "[\(repo)]", block: code)
            }
        }
    }

}
