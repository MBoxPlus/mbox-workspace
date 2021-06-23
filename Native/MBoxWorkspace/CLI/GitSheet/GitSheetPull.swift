//
//  GitSheetPull.swift
//  MBoxWorkspace
//
//  Created by 詹迟晶 on 2020/6/2.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit
import MBoxWorkspaceCore

extension MBCommander.GitSheet {
    open class Pull: Status {
        open class override var description: String? {
            return "Perform git pull for every repo"
        }

        open override func run() throws {
            for repo in self.config.currentFeature.repos {
                UI.section("Pull \(repo.name)") {
                    do {
                        try self.pull(repo: repo)
                    } catch {
                        UI.log(error: "[\(repo.name)] Pull Failed: \(error.localizedDescription)")
                    }
                }
            }
            UI.log(info: "")
            try super.run()
        }

        open func pull(repo: MBConfig.Repo) throws {
            try repo.workRepository?.git?.pull()
        }
    }
}

