//
//  Feature.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/6/17.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

extension MBCommander {
    open class Feature: MBCommander {

        open override func setup() throws {
            self.shouldLockConfig = true
            try super.setup()
        }

        open class override var description: String? {
            return "Manage Features"
        }

        open override func run() throws {
            try super.run()
            if type(of: self) == MBCommander.Feature.self {
                throw ArgumentError.invalidCommand(nil)
            }
        }
    }
}
