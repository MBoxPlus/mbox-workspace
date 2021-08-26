//
//  MBCommander+Workspace.swift
//  MBoxWorkspaceCore
//
//  Created by Whirlwind on 2020/12/17.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxWorkspaceCore

extension MBCommander {
    @_dynamicReplacement(for: setupLauncher(force:))
    open func workspace_setupLauncher(force: Bool = false) throws {
        try self.setupLauncher(force: force)
        try UI.workspace?.syncPlugins()
    }
}
