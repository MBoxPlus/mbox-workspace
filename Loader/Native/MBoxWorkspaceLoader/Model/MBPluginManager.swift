//
//  MBPluginManager.swift
//  MBoxWorkspaceLoader
//
//  Created by 詹迟晶 on 2022/1/27.
//  Copyright © 2022 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxWorkspaceCore

extension MBPluginManager {
    public func tryLoadWorkspace() {
        if let root = MBWorkspace.searchRootPath(MBProcess.shared.rootPath),
           MBProcess.shared.workspace?.rootPath != root {
            MBProcess.shared.workspace = MBWorkspace(rootPath: root)
        }
        if MBProcess.shared.workspace != nil,
           let package = MBPluginManager.shared.package(for: "MBoxWorkspace") {
            package.required = true
        }
    }
}
