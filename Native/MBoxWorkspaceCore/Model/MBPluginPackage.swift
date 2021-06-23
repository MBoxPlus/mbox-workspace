//
//  MBPluginPackage.swift
//  MBoxWorkspace
//
//  Created by 詹迟晶 on 2020/9/11.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

var MBPluginPackageWorkspaceRequiredKey: UInt8 = 0
extension MBPluginPackage {

    public var workspaceRequired: Bool {
        set {
            self.dictionary["REQUIRED_FOR_WORKSPACE"] = newValue
        }
        get {
            guard let v = self.dictionary["REQUIRED_FOR_WORKSPACE"] as? Bool else {
                return false
            }
            return v
        }
    }

}
