//
//  Enable.swift
//  MBoxWorkspace
//
//  Created by 詹迟晶 on 2020/11/17.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxWorkspaceCore

var MBCommanderPluginEnableScopeKey: UInt8 = 0
extension MBCommander.Plugin.Activate {
    public enum Scope {
        case application
        case workspace
        case repository(String)
    }

    @_dynamicReplacement(for: options)
    open class var workspace_options: [Option] {
        var options = self.options
        options << Option("repo", description: "Enable plugin in the specified repository")
        return options
    }

    @_dynamicReplacement(for: flags)
    open class var workspace_flags: [Flag] {
        var flags = self.flags
        flags << Flag("workspace", description: "Enable plugin in current workspace")
        flags << Flag("application", description: "Enable plugin in Application")
        return flags
    }

    @_dynamicReplacement(for: fetchSetting)
    open func workspace_fetchSetting() -> [MBSetting]? {
        var result: [MBSetting]? = []
        if self.isScopeCheckNeeded {
            for scope in self.scopes {
                switch scope {
                case .workspace:
                    for name in self.names {
                        if let package = MBPluginManager.shared.package(for: MBSetting.pluginName(for: name)) {
                            if package.scope != .APPLICATION && package.scope != .WORKSPACE {
                                UI.log(error: "Plugin `\(name)` cannot be enabled in `Workspace` scope")
                                result = nil
                            }
                        }
                    }
                case .application:
                    for name in self.names {
                        if let package = MBPluginManager.shared.package(for: MBSetting.pluginName(for: name)) {
                            if package.scope != .APPLICATION {
                                UI.log(error: "Plugin `\(name)` cannot be enabled in `Application` scope")
                                result = nil
                            }
                        }
                    }
                case .repository(_):
                    continue
                }
            }
        }

        guard result != nil else {
            return result
        }

        return self.scopes.compactMap { scope in
            switch scope {
            case .workspace:
                return self.workspace.userSetting
            case .repository(let name):
                if let repo = self.config.currentFeature.findRepo(name: name).first?.workRepository {
                    return repo.setting
                }
                UI.log(error: "Could not find repo `\(name)`.")
                return nil
            case .application:
                return MBSetting.global
            }
        }
    }

    @_dynamicReplacement(for: setup)
    open func workspace_setup() throws {
        var scopes = [Scope]()
        if self.shiftFlag("application") {
            scopes << .application
        }
        if self.shiftFlag("workspace") {
            scopes << .workspace
        }
        if let repos: [String] = self.shiftOptions("repo") {
            for repo in repos {
                scopes << .repository(repo)
            }
        }
        if scopes.isEmpty {
            scopes << .workspace
        }
        self.scopes = scopes
        try self.setup()
    }

    public var scopes: [Scope] {
        set {
            associateObject(base: self, key: &MBCommanderPluginEnableScopeKey, value: newValue)
        }
        get {
            return associatedObject(base: self, key: &MBCommanderPluginEnableScopeKey, defaultValue: [.workspace])
        }
    }
}
