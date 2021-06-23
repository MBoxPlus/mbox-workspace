//
//  GitSheet.swift
//  MBoxGit
//
//  Created by 詹迟晶 on 2020/6/1.
//  Copyright © 2020 com.bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBCommander {
    open class GitSheet: MBCommander {
        open class override var description: String? {
            return "Execute git command for every repo and format output"
        }

        open class override var forwardCommand: MBCommander.Type? {
            if self == GitSheet.self {
                return GitSheet.Status.self
            }
            return super.forwardCommand
        }

        open override func run() throws {
            try super.run()
        }
    }
}
