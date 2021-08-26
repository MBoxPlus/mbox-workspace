//
//  MBoxWorkspaceLoader.swift
//  MBoxWorkspaceLoader
//
//  Created by Whirlwind on 2020/9/2.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxWorkspaceCore

@objc(MBoxWorkspaceLoader)
open class MBoxWorkspaceLoader: NSObject, MBPluginProtocol {
    public override init() {
        super.init()
        if let root = MBWorkspace.searchRootPath(UI.rootPath),
           UI.workspace?.rootPath != root {
            UI.workspace = MBWorkspace(rootPath: root)
        }
        if UI.workspace != nil,
           let package = MBPluginManager.shared.package(for: "MBoxWorkspace") {
            package.required = true
        }
    }

    public func registerCommanders() {
        MBCommanderGroup.shared.addCommand(MBCommander.Init.self)
    }
}

