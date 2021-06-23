//
//  Open.swift
//  MBoxWorkspace
//
//  Created by 詹迟晶 on 2019/12/10.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxWorkspaceCore

extension MBCommander.Open {
    @_dynamicReplacement(for: pathToOpen(_:))
    open func workspace_pathToOpen(_ path: String?) -> String? {
        let path = self.pathToOpen(path)
        if let path = path {
            return MBWorkspace.searchRootPath(path)
        }
        return nil
    }
}
