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
    @_dynamicReplacement(for: merged)
    public static var workspace_merged: MBSetting {
        let setting = self.merged
        if let workspace = MBProcess.shared.workspace {
            setting.merge(workspace.userSetting)
        }
        return setting
    }

    @_dynamicReplacement(for: all)
    public static var workspace_all: [MBSetting] {
        var value = self.all
        if let workspace = MBProcess.shared.workspace {
            value.insert(contentsOf: workspace.workRepos.compactMap { $0.setting }, at: 0)
            value.insert(workspace.userSetting, at: 0)
        }
        return value
    }
}
