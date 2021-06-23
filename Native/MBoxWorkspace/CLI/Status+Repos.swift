//
//  Status+Repos.swift
//  MBoxWorkspace
//
//  Created by 詹迟晶 on 2021/2/28.
//  Copyright © 2021 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit
import MBoxWorkspaceCore

extension MBCommander.Status {
    open class Repos: MBCommanderStatus {
        public static var supportedAPI: [APIType] {
            return [.none, .api, .plain]
        }

        public static var title: String {
            return "repos"
        }

        public var feature: MBConfig.Feature

        public required init(feature: MBConfig.Feature) {
            self.feature = feature
        }

        public static var showTitle: Bool {
            return false
        }

        // MARK: - API
        public func APIData() throws -> Any?  {
            return try self.feature.repos.compactMap({ repo -> [String: Any]? in
                var branch = repo.lastBranch
                var type = repo.lastType
                if feature.isCurrent, let describe = try repo.workRepository?.git?.currentDescribe() {
                    branch = describe.value
                    type = describe.type
                }
                var hash: [String: Any] = [
                    "name": repo.name,
                    "url": repo.url as Any,
                    "branch": branch as Any,
                    "type": type as Any
                ]
                if !feature.free {
                    hash["target_branch"] = repo.targetBranch
                    hash["base_branch"] = repo.baseBranch
                    hash["base_type"] = repo.baseType
                }

                hash["git_info"] = try Status.gitInfo(repo: repo)

                if let info = try self.repoAPI(for: repo) {
                    hash.merge(info) { (a, b) -> Any in
                        b
                    }
                }
                return hash
            })
        }

        dynamic
        open func repoAPI(for repo: MBConfig.Repo) throws -> [String: Any]? {
            return nil
        }

        // MARK: - Plain
        public func plainData() throws -> [String]?  {
            return self.feature.repos.map { $0.name }
        }

        // MARK: - Text
        public func textRows() throws -> [Row]? {
            let repos = feature.repos
            if repos.isEmpty {
                return [Row(column: "It is empty!")]
            }
            var rows = [Row]()
            for repo in repos {
                try UI.log(verbose: "[\(repo)]") {
                    let row = try Row(columns: self.formatInfo(repo: repo))
                    row.subRows = try self.repoRows(for: repo)
                    rows.append(row)
                }
            }
            return rows
        }

        dynamic
        open func repoRows(for repo: MBConfig.Repo) throws -> [Row]? {
            return nil
        }

        dynamic
        open func formatInfo(repo: MBConfig.Repo) throws -> [[String]] {
            var infos = [[repo.name, repo.url ?? ""]]
            if !feature.isCurrent {
                return infos
            }

            var branch_info: String
            guard let workRepo = repo.workRepository else {
                infos << ["[\("Repo Removed".ANSI(.red))] "]
                return infos
            }

            guard let git = workRepo.git else {
                infos << ["[\("Git Error".ANSI(.red))] "]
                return infos
            }

            let describe = try git.currentDescribe()
            if describe.isCommit {
                branch_info = "commit: " + describe.value[..<10]
            } else if describe.isBranch {
                branch_info = describe.value
            } else {
                branch_info = describe.type + ": " + describe.value
            }
            if !repo.isInFeatureBranch(describe) {
                branch_info = branch_info.ANSI(.red)
            }
            branch_info = "[\(branch_info)]"
            if git.hasConflicts {
                branch_info << "!".ANSI(.red)
            } else if git.isClean {
                branch_info << " "
            } else {
                branch_info << "*".ANSI(.red)
            }

            infos << [branch_info]

            if describe.isBranch {
                infos << Status.getAheadAndBehind(git: git)
            }

            if feature.free {
                return infos
            }
            if let featureBranch = repo.featureBranch,
               describe == .branch(featureBranch) {
                var flag: String? = nil
                var other: String? = nil
                var branch: String?
                if let targetBranch = repo.targetBranch {
                    flag = "->"
                    other = targetBranch
                    branch = targetBranch
                } else if let baseGitPointer = repo.baseGitPointer {
                    if baseGitPointer.isBranch {
                        flag = "->"
                        other = baseGitPointer.value
                        branch = baseGitPointer.value
                    } else {
                        flag = "<-"
                        other = baseGitPointer.description
                    }
                }
                if let flag = flag, let other = other {
                    infos << [flag.ANSI(.black, bright: true), "[\(other)]".ANSI(.black, bright: true)]
                }
                if let branch = branch {
                    infos << [Status.getMergeStatus(git: git, targetBranch: branch)]
                }
            }

            return infos
        }

    }

}

