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

    public func findRepo(url: String) -> MBConfig.Repo? {
        return self.repos.first { $0.url?.lowercased() == url.lowercased() }
    }

    public func findRepo(name: String, owner: String? = nil, searchPackageName: Bool = true) -> [MBConfig.Repo] {
        return self.repos.filter { $0.isName(name, owner: owner, searchPackageName: searchPackageName) }
    }

    public func findRepo(_ repo: MBConfig.Repo) -> MBConfig.Repo? {
        if let url = repo.url, url.count > 0 {
            if let r = findRepo(url: url) {
                return r
            }
        }
        return findRepo(name: repo.name, owner: repo.owner, searchPackageName: false).first
    }

    public func add(repo: MBConfig.Repo) {
        if findRepo(repo) == nil {
            repo.lastBranch = nil
            repo.lastType = nil
            repo.feature = self
            self.repos.append(repo)
            self.repos.sort(by: \.name)
        }
    }

    dynamic
    public func remove(repo: MBConfig.Repo) throws {
        self.repos.removeAll(repo)
        self.repos.sort(by: \.name)
    }

    @discardableResult
    dynamic
    public func merge(feature: MBConfig.Feature) -> [MBConfig.Repo] {
        var addedRepos = [MBConfig.Repo]()
        feature.repos.forEach { repo in
            if self.free { repo.baseGitPointer = nil }
            if let exist = self.repos.first(where: { $0 == repo }) {
                if exist.targetBranch != repo.targetBranch {
                    UI.log(verbose: "Change target branch \(exist.targetBranch ?? "") -> \(repo.targetBranch ?? "")")
                    exist.targetBranch = repo.targetBranch
                }
                if let last = repo.lastGitPointer, last != exist.lastGitPointer {
                    UI.log(verbose: "Change last \(exist.lastGitPointer?.description ?? "") -> \(last)")
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
