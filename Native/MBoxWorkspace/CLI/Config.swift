//
//  Config.swift
//  MBoxWorkspace
//
//  Created by 詹迟晶 on 2019/12/29.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

var MBCommandConfigGlobalKey: UInt8 = 0
var MBCommandConfigWorkspaceKey: UInt8 = 0

extension MBCommander.Config {

    @_dynamicReplacement(for: flags)
    open class var workspace_flags: [Flag] {
        var flags = self.flags
        flags << Flag("global", flag: "g", description: "Use global setting")
        flags << Flag("workspace", flag: "w", description: "Use workspace setting")
        return flags
    }

    @_dynamicReplacement(for: setup)
    open func workspace_setup() throws {
        self.isGlobal = self.shiftFlag("global")
        self.isWorkspace = self.shiftFlag("workspace")
        try self.setup()
    }

    open var isGlobal: Bool {
        set {
            associateObject(base: self, key: &MBCommandConfigGlobalKey, value: newValue)
        }
        get {
            return associatedObject(base: self, key: &MBCommandConfigGlobalKey, defaultValue: false)
        }
    }

    open var isWorkspace: Bool {
        set {
            associateObject(base: self, key: &MBCommandConfigWorkspaceKey, value: newValue)
        }
        get {
            return associatedObject(base: self, key: &MBCommandConfigWorkspaceKey, defaultValue: false)
        }
    }

    @_dynamicReplacement(for: setting)
    open var workspace_setting: MBSetting {
        guard !self.isGlobal,
            let workspace = UI.workspace else {
                return self.setting
        }
        if self.isEdit {
            return workspace.userSetting
        } else if self.isWorkspace {
            return workspace.userSetting
        } else {
            return MBSetting.merged
        }
    }
}
