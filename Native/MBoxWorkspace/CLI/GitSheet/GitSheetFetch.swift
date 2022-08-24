//
//  GitSheetFetch.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2020/6/2.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBCommander.GitSheet {
    open class Fetch: Status {
        open class override var description: String? {
            return "Perform git fetch for every repo"
        }

        open override func run() throws {
            for repo in self.config.currentFeature.repos {
                UI.section("Fetching \(repo.name)") {
                    try? self.fetch(repo: repo)
                }
            }
            UI.log(info: "")
            try super.run()
        }

        open func fetch(repo: MBConfig.Repo) throws {
            try repo.workRepository?.git?.fetch()
        }
    }
}
