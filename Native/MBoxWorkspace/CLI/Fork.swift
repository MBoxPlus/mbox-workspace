//
//  Fork.swift
//  MBoxWorkspace
//
//  Created by 詹迟晶 on 2019/9/30.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxWorkspaceCore

open class ForkApp: ExternalApp {
    public override init(name: String? = nil) {
        super.init(name: name ?? "Fork")
    }
}

extension MBCommander {
    open class Fork: MBCommander {

        open override class var arguments: [Argument] {
            return [Argument("name", description: "Specific git repo", required: true, plural: true)]
        }

        open override class var flags: [Flag] {
            var flags = super.flags
            flags << Flag("all", description: "Open all git repositories.")
            return flags
        }

        open class override var description: String? {
            return "Quckly open git repository in the Fork app."
        }

        open override class func autocompletion(argv: ArgumentParser) -> [String] {
            var completions = super.autocompletion(argv: argv)
            if let config = self.config {
                completions.append(contentsOf: config.currentFeature.repos.map { $0.name })
            }
            return completions
        }

        open override func setup() throws {
            try super.setup()
            self.names = self.shiftArguments("name")
            self.all = self.shiftFlag("all")
        }

        open var names: [String] = []
        open var all: Bool = false

        open override func validate() throws {
            try super.validate()
            if !self.all && self.names.isEmpty {
                throw ArgumentError.missingArgument("name")
            }
            if !application.installed {
                throw UserError("The Application `\(self.application.name!)` maybe not installed.")
            }
        }

        open override func run() throws {
            try super.run()
            try self.open(repos: self.repos())
        }

        open func repos() throws -> [MBConfig.Repo] {
            if self.all { return self.config.currentFeature.repos }
            return try self.names.flatMap { name -> [MBConfig.Repo] in
                let repos = self.config.currentFeature.findRepo(name: name)
                if repos.count > 0 {
                    return repos
                }
                throw UserError("Could not find the repo named `\(name)`.")
            }
        }

        open func open(repos: [MBConfig.Repo]) throws {
            let repos = repos.isEmpty ? self.config.currentFeature.repos : repos
            for repo in repos {
                if try !self.open(repo: repo) {
                    throw RuntimeError("Open Failed!")
                }
            }
        }

        @discardableResult
        open func open(repo: MBConfig.Repo? = nil) throws -> Bool {
            guard let repo = repo else {
                throw UserError("Could not open the fork at the root path. It is not a git repository.")
            }
            let path = repo.workingPath
            if !path.isDirectory {
                throw UserError("The path is invalid for repo `\(repo)`.")
            }
            return application.open(directory: path)
        }

        open lazy var application: ExternalApp = getApp()
        open func getApp() -> ExternalApp {
            return ForkApp()
        }
    }
}
