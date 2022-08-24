//
//  GitSheetPush.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2020/6/2.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBCommander.GitSheet {
    open class Push: Status {
        open class override var description: String? {
            return "Perform git push for every repo"
        }

        open override func run() throws {
            for repo in self.config.currentFeature.repos {
                UI.section("Push \(repo.name)") {
                    if let workRepo = repo.workRepository {
                        do {
                            try self.push(repo: workRepo)
                        } catch {
                            UI.log(error: "[\(repo.name)] Push Failed: \(error.localizedDescription)")
                        }
                    } else {
                        UI.log(warn: "[\(repo)] Repo not exists.")
                    }
                }
            }
            UI.log(info: "")
            try super.run()
        }

        open func push(repo: MBWorkRepo) throws {
            try repo.git?.push()
        }
    }
}
