//
//  MBWorkspacePluginProtocol.swift
//  MBoxWorkspace
//
//  Created by 詹迟晶 on 2019/9/30.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

public protocol MBWorkspacePluginProtocol: MBPluginProtocol {
    func disablePlugin(workspace: MBWorkspace) throws
    func enablePlugin(workspace: MBWorkspace, from version: String?) throws
}
