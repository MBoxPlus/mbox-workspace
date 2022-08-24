//
//  MBProcess.swift
//  MBoxWorkspaceLoader
//
//  Created by 詹迟晶 on 2021/11/23.
//  Copyright © 2021 bytedance. All rights reserved.
//

import Foundation

extension MBProcess {
    @_dynamicReplacement(for: plugins)
    public var workspace_plugins: [String: [MBSetting.PluginDescriptor]] {
        var value = self.plugins
        guard let workspace = self.workspace else {
            return value
        }

        workspace.plugins.forEach { (name, descs) in
            var v = value[name] ?? []
            v.append(contentsOf: descs)
            value[name] = v
        }
        return value
    }

    @_dynamicReplacement(for: recommendedPlugins)
    public var workspace_recommendedPlugins: [String: [MBSetting.PluginDescriptor]] {
        var value = self.recommendedPlugins
        value.removeValue(forKey: "MBoxWorkspace")
        return value
    }
}

