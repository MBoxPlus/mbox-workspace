//
//  MBWorkspaceSetting.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/12/17.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

extension MBSetting {
    public var workspace: Workspace {
        return self.value(forPath: "workspace")
    }

    @objc(MBSettingWorkspace)
    open class Workspace: MBCodableObject {
        public static let BranchPrefix = "feature/"

        @Codable
        open var branchPrefix: String? = nil

        @Codable
        open var checkoutFromCommit: Bool = false

        @Codable
        open var useWorktree: Bool = true
    }
}
