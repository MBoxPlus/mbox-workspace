//
//  List.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/8/15.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBCommander.Feature {
    open class List: Feature {
        open class override var description: String? {
            return "List all features"
        }

        open override func setup() throws {
            try super.setup()
            self.shouldLockConfig = false
        }

        open override func run() throws {
            try super.run()
            if MBProcess.shared.apiFormatter != .none {
                try outputAPI()
            } else {
                try output()
            }
        }

        open func output() throws {
            for (_, feature) in self.config.features {
                var name = "[\(feature.name)]"
                if feature.isCurrent { name = name.ANSI(.yellow) }
                UI.log(info: name) {
                    for repo in feature.repos {
                        UI.log(info: repo.name)
                    }
                }
            }
        }

        open func outputAPI() throws {
            let info = self.config.features.map { (key: String, value: MBConfig.Feature) -> (String, [String]) in
                return (value.name, value.repos.map { $0.name } )
            }
            let dict = Dictionary(info)
            UI.log(api: dict)
        }
    }
}

