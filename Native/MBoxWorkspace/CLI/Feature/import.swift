//
//  import.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/6/23.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit
import MBoxWorkspaceCore

extension MBCommander.Feature {
    open class Import: Feature {
        open class override var description: String? {
            return "Import a json/url as a feature"
        }

        open class override var arguments: [Argument] {
            var arguments = super.arguments
            arguments << Argument("string", description: "Feature JSON/URL", required: true)
            return arguments
        }

        open override class var options: [Option] {
            var options = super.options
            options << Option("name", description: "Use the name to override the name from the json")
            return options
        }

        dynamic
        open override class var flags: [Flag] {
            var flags = super.flags
            flags << Flag("check-branch-exists", description: "Check if the feature branch exists")
            flags << Flag("keep-changes", description: "Create a new feature with local changes")
            flags << Flag("recurse-submodules", description: "After the clone is created, initialize all submodules within, using their default settings.")
            return flags
        }

        dynamic
        open override func setup() throws {
            self.checkBranchExists = self.shiftFlag("check-branch-exists", default: true)
            self.keep = self.shiftFlag("keep-changes")
            self.recurseSubmodules = self.shiftFlag("recurse-submodules")
            self.name = self.shiftOption("name")
            let string: String = try self.shiftArgument("string")
            if let url = URL(string: string) {
                if let json = url.queryValue(for: "json") {
                    self.json = json
                } else {
                    throw UserError("The paramter `json` is required.")
                }
            } else {
                self.json = string
            }
            try super.setup()
        }

        public var json: String = ""
        public var feature: MBConfig.Feature!
        public var name: String?

        public var checkBranchExists: Bool = true
        public var keep: Bool = false
        public var recurseSubmodules: Bool? = nil

        dynamic
        open override func validate() throws {
            try super.validate()
            self.feature = try self.buildFeature(fromString: self.json)
            try self.validateBranch()
        }

        dynamic
        open func buildFeature(fromString string: String) throws -> MBConfig.Feature {
            return try MBConfig.Feature.load(fromString: string, coder: .json)
        }

        open func setupName() throws {
            if let name = self.name {
                self.feature.name = name
            }
        }

        open func mergeFeature() throws {
            if let existFeature = config.feature(withName: self.feature.name) {
                UI.section("Merge an existing feature `\(existFeature.name)`") {
                    existFeature.merge(feature: self.feature)
                }
            } else {
                UI.section("Create a new feature `\(self.feature.name)`") {
                    self.config.addFeature(self.feature)
                }
            }

            self.config.save()
            UI.log(info: "Import feature success!")
        }

        dynamic
        open override func run() throws {
            try super.run()
            try self.setupName()
            try self.mergeFeature()

            UI.log(info: "")

            try UI.section("Fetch exists repos") {
                try self.fetchRepos()
            }

            var args = [self.feature.name, "--pull"]
            if keep {
                args << "--keep-changes"
            }
            if recurseSubmodules == true {
                args << "--recurse-submodules"
            }
            try self.switchFeature(args: args)
        }

        dynamic
        open func switchFeature(args: [String]) throws {
            try self.invoke(Start.self, argv: ArgumentParser(arguments: args))
        }

        dynamic
        open var featureRepos: [MBConfig.Repo] {
            return self.feature.repos
        }

        open func validateBranch() throws {
            try UI.section("Validate Git") {
                for repo in self.featureRepos {
                    try UI.log(verbose: "[\(repo)]") {
                        if repo.dictionary["url"] == nil {
                            throw UserError("Missing the `url`:\n\(repo.dictionary)")
                        }
                        guard let urlString = repo.url,
                            let url = URL(string: urlString) else {
                            throw UserError("The repo `\(repo)` should have a url.")
                        }
                        if self.checkBranchExists, let last = repo.lastGitPointer {
                            if !last.isCommit {
                                let remotes = try GitHelper.lsRemote(at: url, showBranch: last.isBranch, showTag: last.isTag)
                                if !remotes.contains(last.value) {
                                    throw UserError("There is not the \(last) in the repo `\(repo)`!")
                                }
                            }
                        }
                        if repo.targetBranch == nil, repo.baseGitPointer?.isBranch == true {
                            repo.targetBranch = repo.baseBranch
                        }
                        if !self.feature.free && repo.targetBranch == nil && (repo.baseGitPointer == nil || repo.baseGitPointer?.isBranch == false) {
                            throw UserError("There is not a `target_branch`/`base_branch` in the repo `\(repo)`.")
                        }
                    }
                }
            }
        }

        open func fetchRepos() throws {
            for repo in self.featureRepos {
                try UI.log(verbose: "[\(repo)]") {
                    try repo.originRepository?.git?.fetch()
                }
            }
        }
    }
}
