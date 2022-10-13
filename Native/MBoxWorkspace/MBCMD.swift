//
//  MBCMD.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/8/20.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Cocoa
import MBoxCore

extension MBCMD {

    public var workspace: MBWorkspace { return Workspace }

    @_dynamicReplacement(for: setup())
    public func workspace_setup() {
        self.setup()
        self.workingDirectory = self.workspace.rootPath
    }

    @_dynamicReplacement(for: setupEnvironment(_:))
    public func workspace_setupEnvironment(_ base: [String: String]? = nil) -> [String: String] {
        var env = self.setupEnvironment(base)
        env["MBOX_ROOT"] = workspace.rootPath
        env["MBOX_PLUGIN_PATHS"] = MBPluginManager.shared.modulesHash.keys.compactMap { $0.path }.joined(separator: ":")

        let feature = workspace.config.currentFeature
        env["MBOX_FEATURE"] = feature.name
        env["MBOX_REPOS"] = feature.repos.map{ $0.name }.joined(separator: ",")
        return env
    }
}
