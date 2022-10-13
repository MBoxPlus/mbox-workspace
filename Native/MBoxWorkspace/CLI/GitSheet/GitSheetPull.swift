//
//  GitSheetPull.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2020/6/2.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBCommander.GitSheet {
    open class Pull: Status {
        open class override var description: String? {
            return "Perform git pull for every repo"
        }

        open override func run() throws {
            for repo in self.config.currentFeature.repos {
                try UI.allowAsyncExec(title: "Pull \(repo.name)") {
                    do {
                        try self.pull(repo: repo)
                    } catch {
                        throw RuntimeError("[\(repo.name)] Pull Failed: \(error.localizedDescription)")
                    }
                }
            }
            try UI.wait()
            UI.log(info: "")
            try super.run()
        }

        open func pull(repo: MBConfig.Repo) throws {
            try repo.workRepository?.git?.pull()
        }
    }
}


