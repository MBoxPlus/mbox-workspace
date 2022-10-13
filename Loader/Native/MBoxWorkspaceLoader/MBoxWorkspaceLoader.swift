//
//  MBoxWorkspaceLoader.swift
//  MBoxWorkspaceLoader
//
//  Created by Whirlwind on 2020/9/2.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
@_exported import MBoxWorkspaceCore

@objc(MBoxWorkspaceLoader)
open class MBoxWorkspaceLoader: NSObject, MBPluginProtocol {
    public override init() {
        super.init()
        MBPluginManager.shared.tryLoadWorkspace()
    }

    public func registerCommanders() {
        MBCommanderGroup.shared.addCommand(MBCommander.Init.self)
    }
}
