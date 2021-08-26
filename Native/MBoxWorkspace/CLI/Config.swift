//
//  Config.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/12/29.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

var MBCommandConfigGlobalKey: UInt8 = 0
var MBCommandConfigWorkspaceKey: UInt8 = 0

extension MBCommander.Config.Scope {
    public static let Workspace = MBCommander.Config.Scope("workspace")
}

extension MBCommander.Config {

    @_dynamicReplacement(for: flags)
    open class var workspace_flags: [Flag] {
        var flags = self.flags
        flags << Flag("workspace", flag: "w", description: "Use workspace setting")
        return flags
    }

    @_dynamicReplacement(for: setup)
    open func workspace_setup() throws {
        if self.shiftFlag("workspace", default: true) {
            self.scope = .Workspace
        }
        try self.setup()
    }

    @_dynamicReplacement(for: setting)
    open var workspace_setting: MBCodableObject & MBFileProtocol {
        guard self.scope == Scope.Workspace else {
            return self.setting
        }
        if self.isEdit || self.isDelete {
            return self.workspace.userSetting
        } else {
            return MBSetting.merged
        }
    }
}
