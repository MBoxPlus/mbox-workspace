//
//  Git.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/6/12.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBCommander {
    open class Git: Exec {
        open class override var description: String? {
            return "Execute git command for every repo"
        }

        open class override var arguments: [Argument] {
            return [Argument("command", description: "The command will be executed", required: true)]
        }

        open override var cmd: MBCMD {
            let cmd = GitCMD()
            cmd.showOutput = true
            if let path = MBProcess.shared.workspace?.rootPath {
                cmd.workingDirectory = path
            }
            return cmd
        }

        open class override var onlyRunInWorkspace: Bool {
            return false
        }

        open override var onlyRunInWorkspace: Bool {
            if self.argv.remainder.count == 0 {
                return true
            }
            return super.onlyRunInWorkspace
        }

        open override func runInRepo(repo: MBWorkRepo, cmd: MBCMD, args: String) -> Int32 {
            MBProcess.shared.with(verbose: false) {
                if let git = repo.git, let branch = git.currentBranch {
                    if git.trackBranch(autoMatch: false) == nil, let remoteBranch = git.remoteBranch(named: branch) {
                        if git.setTrackBranch(local: branch, remote: remoteBranch.name) {
                            UI.log(info: "Set the current track branch to `\(remoteBranch.name)`.", pip: .ERR)
                        }
                    }
                }
            }
            return super.runInRepo(repo: repo, cmd: cmd, args: args)
        }
    }
}
