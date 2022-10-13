//
//  MBProcess.swift
//  MBoxWorkspaceCore
//
//  Created by Whirlwind on 2020/9/7.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

var MBProcessShowRootPathKey: UInt8 = 0
var MBProcessWorkspaceKey: UInt8 = 0
extension MBProcess {
    public var showRootPath: Bool {
        set {
            associateObject(base: self, key: &MBProcessShowRootPathKey, value: newValue)
        }
        get {
            return associatedObject(base: self, key: &MBProcessShowRootPathKey, defaultValue: true)
        }
    }

    public var workspace: MBWorkspace? {
        set {
            if self.workspace == newValue { return }
            associateObject(base: self, key: &MBProcessWorkspaceKey, value: newValue)
            if let logDirectory = newValue?.logDirectory {
                UI.logger.setFilePath(with: logDirectory)
            }
        }
        get {
            return associatedObject(base: self, key: &MBProcessWorkspaceKey)
        }
    }

    public var feature: MBConfig.Feature? {
        return self.workspace?.config.currentFeature
    }
}
