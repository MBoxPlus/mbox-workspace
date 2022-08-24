//
//  MBWorkspacePluginProtocol.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/9/30.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
@_exported import MBoxCore

public protocol MBWorkspacePluginProtocol {
    func disablePlugin(workspace: MBWorkspace) throws
    func enablePlugin(workspace: MBWorkspace, from version: String?) throws
}
