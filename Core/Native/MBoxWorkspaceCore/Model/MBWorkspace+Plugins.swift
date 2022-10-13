//
//  MBWorkspace+Plugins.swift
//  MBoxWorkspaceCore
//
//  Created by Whirlwind on 2020/12/17.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

extension MBWorkspace {
    dynamic
    public func syncPlugins() throws {
        let lastPlugins = self.config.plugins.mapKeysAndValues { (key, value) -> (String, String) in
            return (key.lowercased(), value)
        }

        var resolvedPlugins = [String]()
        var status = (new: 0, delete: 0, update: 0)
        for (package, modules) in MBPluginManager.shared.modulesHash {
            for module in modules {
                let name = module.name.lowercased()
                if resolvedPlugins.contains(name) { continue }
                resolvedPlugins.append(name)
                if let lastVersion = lastPlugins[name] {
                    if lastVersion.isVersion(greaterThanOrEqualTo: package.version) { continue }
                    // Update
                    status.update += 1
                    try UI.log(info: "Update Module \(module.name) \(package.version) (was \(lastVersion))", pip: .ERR) {
                        if let main = module.mainClass as? MBWorkspacePluginProtocol {
                            try self.enablePlugin(main, from: lastVersion)
                        }
                    }
                } else {
                    // Add
                    status.new += 1
                    try UI.log(info: "Enable Module \(module.name) \(package.version)", pip: .ERR) {
                        if let main = module.mainClass as? MBWorkspacePluginProtocol {
                            try self.enablePlugin(main)
                        }
                    }
                }
            }
        }

        // Remove
        let removedModules = Set(lastPlugins.keys).subtracting(MBPluginManager.shared.modules.map(\.name).map { $0.lowercased() })
        for name in removedModules {
            status.delete += 1
            if let module = MBPluginManager.shared.module(for: name) {
                try UI.log(info: "Disable Module \(module.name) \(module.package!.version)", pip: .ERR) {
                    if let main = module.mainClass as? MBWorkspacePluginProtocol {
                        try self.disablePlugin(main)
                    }
                }
            }
        }
        if status.new > 0 || status.delete > 0 || status.update > 0 {
            UI.log(info: "Module new: \(status.new), update: \(status.update), delete: \(status.delete)", pip: .ERR)
            self.config.version = MBoxCore.bundle.shortVersion
            self.config.plugins = Dictionary(MBPluginManager.shared.modules.map {
                return ($0.name, $0.package.version)
            })
            self.config.save()
        }
    }

    dynamic
    public func enablePlugin(_ plugin: MBWorkspacePluginProtocol, from oldVersion: String? = nil) throws {
        try plugin.enablePlugin(workspace: self, from: oldVersion)
    }

    dynamic
    public func disablePlugin(_ plugin: MBWorkspacePluginProtocol) throws {
        try plugin.disablePlugin(workspace: self)
    }
}

