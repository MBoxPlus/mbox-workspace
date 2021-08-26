//
//  Open.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/12/10.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxWorkspaceCore

extension MBCommander.Open {
    @_dynamicReplacement(for: autocompletion(argv:))
    open class func workspace_autocompletion(argv: ArgumentParser) -> [String] {
        var completions = self.autocompletion(argv: argv)
        if let config = self.config {
            completions.append(contentsOf: config.currentFeature.repos.map { $0.name })
        }
        return completions
    }

    @_dynamicReplacement(for: expandPath(_:base:))
    open func workspace_expandPath(_ path: String, base: String? = nil) -> String {
        return self.expandPath(path, base: base ?? Workspace.rootPath)
    }

    @_dynamicReplacement(for: pathForApp(_:))
    open func workspace_pathForApp(_ paths: [(path: String, app: ExternalApp?)]) -> [(path: String, app: ExternalApp?)] {
        var paths = self.pathForApp(paths)
        paths = self.repos(for: paths)
        return paths
    }

    open func repos(for names: [(path: String, app: ExternalApp?)]) -> [(path: String, app: ExternalApp?)] {
        if names.isEmpty {
            return [(path: self.workspace.rootPath, app: nil)]
        }
        var values = [(path: String, app: ExternalApp?)]()
        for (name, app) in names {
            if app == nil, !name.contains("/") {
                let repos = self.config.currentFeature.findRepo(name: name)
                if !repos.isEmpty {
                    values.append(contentsOf: repos.map(\.workingPath).map { (path: $0, app: nil) })
                    continue
                }
            }
            values.append((path: name, app: nil))
        }
        return values
    }
}
