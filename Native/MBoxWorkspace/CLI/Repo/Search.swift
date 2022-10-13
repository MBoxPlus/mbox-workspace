//
//  Search.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/7/27.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBCommander.Repo {
    open class Search: Repo {

        open override class var arguments: [Argument] {
            return [Argument("name", description: "The name to search", required: true)]
        }

        dynamic
        open override class var flags: [Flag] {
            return super.flags
        }

        dynamic
        open override func setup() throws {
            try super.setup()
            self.shouldLockConfig = false
            self.name = try self.shiftArgument("name")
        }

        open override func run() throws {
            try super.run()
            guard let repo = try self.search(name: name) else {
                throw UserError("Could not find `\(name)`.")
            }
            UI.log(api: repo.toCodableObject() as! [String: Any])
        }

        var name: String = ""

        dynamic
        open func search(name: String, owner: String? = nil) throws -> MBConfig.Repo? {
            let repos = self.config.currentFeature.findRepo(name: name, owner: owner)
            if repos.count > 1 {
                throw UserError("Multiple repositories found: \(repos)")
            }
            return repos.first
        }

    }
}
