//
//  Export.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/6/23.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBCommander.Feature {
    open class Export: Feature {
        open class override var description: String? {
            return "Export a json from feature"
        }

        open class override var arguments: [Argument] {
            var arguments = super.arguments
            arguments << Argument("name", description: "The feature name will be exported.")
            return arguments
        }

        dynamic
        open override func setup() throws {
            try super.setup()
            if MBProcess.shared.apiFormatter == .none {
                MBProcess.shared.apiFormatter = .json
            }
            self.name = self.shiftArgument("name")
            if let name = self.name {
                guard let feature = self.config.feature(withName: name) else {
                    throw UserError("Could not find a feature which named `\(name)`.")
                }
                self.feature = feature
            } else {
                self.feature = self.config.currentFeature
            }
            self.shouldLockConfig = false
        }

        public var name: String?
        public var feature: MBConfig.Feature!

        dynamic
        open func postExport(json:String) -> String{
            return json
        }

        dynamic
        open override func run() throws {
            try super.run()
            try UI.section("Fetch Remote Status") {
                try self.feature.eachRepos { repo in
                    guard let git = repo.workRepository?.git else {
                        throw RuntimeError("Git Error: \(repo)")
                    }
                    repo.url = git.url ?? repo.url
                    if repo.url == nil {
                        UI.log(verbose: "[\(repo)] The git url is empty.")
                        return
                    }
                    let localStatus = try git.currentDescribe()
                    repo.lastGitPointer = localStatus
                    try self.validateRemote(repo: repo)
                }
            }
            try UI.section("Export Feature `\(self.feature.name)`") {
                var json = try self.feature.export()
                json = postExport(json: json)
                UI.log(info: json, api: true)
            }
        }

        open func validateRemote(repo: MBConfig.Repo) throws {
             if !repo.lastGitPointer!.isBranch {
                return
            }
            guard let git = repo.workRepository?.git else {
                throw UserError("[\(repo)] The `\(repo.workingPath)` not exists.")
            }
            guard let remoteBranch = git.trackBranch() else {
                throw UserError("[\(repo)] The \(repo.lastGitPointer!) is not pushed to the remote.")
            }
            let mergeStatus = try git.checkMergeStatus(curBranch: repo.lastGitPointer!.value, target: .branch(remoteBranch))
            if mergeStatus == .diverged || mergeStatus == .forward {
                throw UserError("[\(repo)] The \(repo.lastGitPointer!) is not pushed to the remote.")
            } else {
                UI.log(verbose: "The \(repo.lastGitPointer!) has be pushed to the remote.")
            }
        }

    }
}
