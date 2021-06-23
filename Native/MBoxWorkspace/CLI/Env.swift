//
//  Env.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/9/22.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxWorkspaceCore

extension MBCommander.Env {

    @_dynamicReplacement(for: run())
    open func workspace_run() throws {
        try run()
        var args = [String]()
        if let mode = self.mode {
            args.append("--only")
            args.append(mode)
        }
        try self.invoke(Status.self, argv: ArgumentParser(arguments: args))
    }

    @_dynamicReplacement(for: sections())
    open class func workspace_sections() -> [String] {
        return ["ROOT"] + sections()
    }

    @_dynamicReplacement(for: show(section:))
    open func workspace_show(section: String) throws {
        if section == "ROOT" {
            try showRoot()
        } else {
            try show(section: section)
        }
    }

    open func showRoot() throws {
        UI.log(info: "[ROOT]:  "  + self.workspace.rootPath)
    }
}
