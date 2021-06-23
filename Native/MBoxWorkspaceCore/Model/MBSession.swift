//
//  MBUI.swift
//  MBoxWorkspaceCore
//
//  Created by 詹迟晶 on 2020/9/7.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

var MBSessionRootPathKey: UInt8 = 0
var MBSessionWorkspaceKey: UInt8 = 0
extension MBSession {

    public var workspace: MBWorkspace? {
        set {
            if self.workspace == newValue { return }
            associateObject(base: self, key: &MBSessionWorkspaceKey, value: newValue)
            self.logDirectory = newValue?.logDirectory
        }
        get {
            return associatedObject(base: self, key: &MBSessionWorkspaceKey)
        }
    }

    public var feature: MBConfig.Feature? {
        return self.workspace?.config.currentFeature
    }

    @_dynamicReplacement(for: requiredPlugins(_:))
    public func workspace_requiredPlugins(_ packages: [MBPluginPackage]) -> [MBPluginPackage] {
        var value = self.requiredPlugins(packages)
        if self.workspace == nil {
            return value
        }
        for package in packages {
            if package.workspaceRequired && !value.contains(package) {
                value.append(package)
            }
        }
        return value
    }

    @_dynamicReplacement(for: plugins)
    open var workspacePlugins: [String: [MBSetting.PluginDescriptor]] {
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
    open var workspace_recommendedPlugins: [String: [MBSetting.PluginDescriptor]] {
        var value = self.recommendedPlugins
        value.removeValue(forKey: getModuleName(forClass: MBWorkspace.self))
        return value
    }
}

