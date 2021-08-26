//
//  Git+Config.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2021/8/20.
//  Copyright © 2021 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit
import MBoxWorkspaceCore

extension MBCommander.Git {
    @objc(MBCommanderGitConfig)
    open class Config: Git {
        open override class var flags: [Flag] {
            var flags = super.flags
            flags << Flag("workspace", description: "use the workspace config file")
            return flags
        }

        open override func setup() throws {
            if self.shiftFlag("workspace") {
                self.level = Self.WorkspaceLevel
            }
            try super.setup()
        }

        open var level: String?
        public static let WorkspaceLevel = "Workspace"

        open override var cmd: MBCMD {
            let cmd = super.cmd as! GitCMD
            cmd.pager = false
            return cmd
        }

        open override var args: [String] {
            var args = super.args
            args.insert(contentsOf: ["config"], at: 0)
            if self.level == Self.WorkspaceLevel {
                args.insert(contentsOf: ["-f", self.workspace.gitConfigPath], at: 1)
            }
            return args
        }

        open override var onlyRunInWorkspace: Bool {
            if self.level == Self.WorkspaceLevel {
                return true
            }
            for flag in ["global", "system"] {
                if (try? Flag(flag).parse(self.argv, shift: false)) == true {
                    return true
                }
            }
            return super.onlyRunInWorkspace
        }
    }
}
