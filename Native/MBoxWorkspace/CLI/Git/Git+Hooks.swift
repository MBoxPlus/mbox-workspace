//
//  Git+Hooks.swift
//  MBoxWorkspace
//
//  Created by 詹迟晶 on 2021/8/20.
//  Copyright © 2021 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit
import MBoxWorkspaceCore

extension MBCommander.Git {
    open class Hooks: MBCommander {
        open override class var description: String? {
            return "Show/Set the git hooks for workspace"
        }

        open override class var flags: [Flag] {
            var flags = super.flags
            flags << Flag("enable", description: "Enable workspace hooks")
            flags << Flag("disable", description: "Enable workspace hooks")
            return flags
        }

        open override func setup() throws {
            if self.shiftFlag("disable") {
                self.enable = false
            }
            if self.shiftFlag("enable") {
                self.enable = true
            }
            try super.setup()
        }

        open var enable: Bool?

        open override func run() throws {
            try super.run()
            if let enable = self.enable {
                try UI.with(verbose: true) {
                    try self.workspace.setupGitHooks(enable: enable)
                }
            } else {
                if let path = try self.workspace.gitHooks() {
                    UI.log(info: "Workspace Git Config File: \(self.workspace.gitConfigPath)\n    Workspace Hooks Directory: \(path)")
                } else {
                    UI.log(info: "No Workspace Hooks.")
                }
            }
        }
    }
}
