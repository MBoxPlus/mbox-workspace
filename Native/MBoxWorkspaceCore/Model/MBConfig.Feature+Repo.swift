//
//  MBConfig.Feature+Repo.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/6/14.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

extension MBConfig.Feature {

    open func findRepo(url: String) -> MBConfig.Repo? {
        return self.repos.first { $0.url?.lowercased() == url.lowercased() }
    }

    open func findRepo(name: String, owner: String? = nil, searchPackageName: Bool = true) -> [MBConfig.Repo] {
        return self.repos.filter { $0.isName(name, owner: owner, searchPackageName: searchPackageName) }
    }

    open func findRepo(_ repo: MBConfig.Repo) -> MBConfig.Repo? {
        if let url = repo.url, url.count > 0 {
            if let r = findRepo(url: url) {
                return r
            }
        }
        return findRepo(name: repo.name, owner: repo.owner, searchPackageName: false).first
    }

    @discardableResult
    open func add(repo: MBConfig.Repo, base branch: String? = nil) -> MBConfig.Repo {
        var newRepo = findRepo(repo)
        if newRepo == nil {
            newRepo = repo.copy() as? MBConfig.Repo
            newRepo?.lastBranch = nil
            newRepo?.lastType = nil
            newRepo?.feature = self
            self.repos.append(newRepo!)
        }
        if let baseBranch = branch {
            newRepo!.baseGitPointer = .branch(baseBranch)
        }
        return newRepo!
    }

    dynamic
    open func remove(repo: MBConfig.Repo) throws {
        repos.removeAll(repo)
    }

    @discardableResult
    dynamic
    open func merge(feature: MBConfig.Feature) -> [MBConfig.Repo] {
        var addedRepos = [MBConfig.Repo]()
        feature.repos.forEach { repo in
            if self.free { repo.baseGitPointer = nil }
            if let exist = self.repos.first(where: { $0 == repo }) {
                exist.targetBranch = repo.targetBranch
                if let last = repo.lastGitPointer {
                    exist.lastGitPointer = last
                }
            } else {
                addedRepos << repo
                UI.log(verbose: "The repo `\(repo)` was added.")
            }
        }
        repos.append(contentsOf: addedRepos)
        return addedRepos
    }
}
