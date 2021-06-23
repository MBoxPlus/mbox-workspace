//
//  Repo.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/7/27.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

extension MBCommander {
    open class Repo: MBCommander {
        open class override var description: String? {
            return "Manage Repos"
        }

        open override func setup() throws {
            self.shouldLockConfig = true
            try super.setup()
        }

        open override func run() throws {
            try super.run()
            if type(of: self) == MBCommander.Repo.self {
                throw ArgumentError.invalidCommand(nil)
            }
        }
    }
}
