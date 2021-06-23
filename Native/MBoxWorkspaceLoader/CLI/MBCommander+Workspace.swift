//
//  MBCommander+Workspace.swift
//  MBoxWorkspaceCore
//
//  Created by 詹迟晶 on 2020/12/17.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxWorkspaceCore

extension MBCommander {
    @_dynamicReplacement(for: setupLauncher(force:))
    open func workspace_setupLauncher(force: Bool = false) throws {
        try self.setupLauncher(force: force)
        if force || requireSetupLauncher {
            try UI.workspace?.syncPlugins()
        }
    }
}
