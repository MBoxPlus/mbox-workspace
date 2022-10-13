//
//  Enable.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2020/11/17.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

var MBCommanderPluginEnableScopeKey: UInt8 = 0
extension MBCommander.Plugin.Activate {
    public enum Scope {
        case application
        case workspace
        case repository(String)
    }

    @_dynamicReplacement(for: options)
    public class var workspace_options: [Option] {
        var options = self.options
        options << Option("repo", description: "Enable plugin in the specified repository")
        return options
    }

    @_dynamicReplacement(for: flags)
    public class var workspace_flags: [Flag] {
        var flags = self.flags
        flags << Flag("workspace", description: "Enable plugin in current workspace")
        flags << Flag("application", description: "Enable plugin in Application")
        return flags
    }

    @_dynamicReplacement(for: fetchSetting)
    public func workspace_fetchSetting() -> [MBSetting]? {
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
    public func workspace_setup() throws {
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
