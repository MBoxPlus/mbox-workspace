//
//  MBWorkspace+Plugins.swift
//  MBoxWorkspaceCore
//
//  Created by 詹迟晶 on 2020/12/17.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

extension MBWorkspace {
    dynamic
    open func syncPlugins() throws {
        let lastPlugins = self.config.plugins.mapKeysAndValues { (key, value) -> (String, String) in
            return (key.lowercased(), value)
        }

        var resolvedPlugins = [String]()
        var status = (new: 0, delete: 0, update: 0)
        for package in MBPluginManager.shared.packages {
            let name = package.name.lowercased()
            if resolvedPlugins.contains(name) { continue }
            resolvedPlugins.append(name)
            if let lastVersion = lastPlugins[name] {
                if lastVersion.isVersion(greaterThanOrEqualTo: package.version) { continue }
                // Update
                status.update += 1
                try UI.log(info: "Update Plugin \(package.name) \(package.version) (was \(lastVersion))", pip: .ERR) {
                    for bundle in package.pluginBundles {
                        if let main = bundle.mainClass as? MBWorkspacePluginProtocol {
                            try self.enablePlugin(main, from: lastVersion)
                        }
                    }
                }
            } else {
                // Add
                status.new += 1
                try UI.log(info: "Enable Plugin \(package.name) \(package.version)", pip: .ERR) {
                    for bundle in package.pluginBundles {
                        if let main = bundle.mainClass as? MBWorkspacePluginProtocol {
                            try self.enablePlugin(main)
                        }
                    }
                }
            }
        }

        // Remove
        let removedPlugins = Set(lastPlugins.keys).subtracting(MBPluginManager.shared.packages.map(\.name).map { $0.lowercased() })
        for name in removedPlugins {
            status.delete += 1
            if let package = MBPluginManager.shared.package(for: name) {
                try UI.log(info: "Disable Plugin \(package.name) \(package.version)", pip: .ERR) {
                    for bundle in package.pluginBundles {
                        if let main = bundle.mainClass as? MBWorkspacePluginProtocol {
                            try self.disablePlugin(main)
                        }
                    }
                }
            }
        }
        if status.new > 0 || status.delete > 0 || status.update > 0 {
            UI.log(info: "Plugin new: \(status.new), update: \(status.update), delete: \(status.delete)", pip: .ERR)
            self.config.version = MBoxCore.bundle.shortVersion
            self.config.plugins = Dictionary(uniqueKeysWithValues: MBPluginManager.shared.packages.map {
                return ($0.name, $0.version)
            })
            self.config.save()
        }
    }

    dynamic
    open func enablePlugin(_ plugin: MBWorkspacePluginProtocol, from oldVersion: String? = nil) throws {
        try plugin.enablePlugin(workspace: self, from: oldVersion)
    }

    dynamic
    open func disablePlugin(_ plugin: MBWorkspacePluginProtocol) throws {
        try plugin.disablePlugin(workspace: self)
    }
}

