//
//  Free.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/6/19.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBCommander.Feature {
    open class Free: Feature {

        open class override var description: String? {
            return "Switch to the `Free Mode` feature"
        }

        open override func run() throws {
            try super.run()
            try self.invoke(Start.self)
        }
    }
}
