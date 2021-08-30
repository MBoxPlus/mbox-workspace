//
//  Go.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/7/24.
//  Copyright © 2019 bytedance. All rights reserved.
//

import MBoxCore
import MBoxWorkspaceCore

extension MBCommander {
    open class Go: MBCommander {

        open override class var arguments: [Argument] {
            return [Argument("name", description: "Specific workspace file to open", required: false)]
        }

        open override class var description: String? {
            return "Quickly open path or workspace."
        }

        open override class func autocompletion(argv: ArgumentParser) -> [String] {
            var completions = super.autocompletion(argv: argv)
            if let workspace = self.workspace {
                completions.append(contentsOf: workspace.workspacePaths.keys)
            }
            return completions
        }

        open override func setup() throws {
            try super.setup()
            self.name = self.shiftArgument("name")
        }

        open var name: String?

        open override func run() throws {
            try super.run()
            var application: String? = nil
            var path: String
            let workspacePaths = self.workspace.workspacePaths
            if let name = self.name {
                let hash = Dictionary(uniqueKeysWithValues: workspacePaths.map({
                    ($0.key.lowercased(), $0)
                }))
                if let info = hash[name.lowercased()] {
                    application = info.value.isEmpty ? nil : info.value
                    path = self.workspace.rootPath.appending(pathComponent: info.key)
                } else {
                    throw RuntimeError("Unknown workspace file: \(name)")
                }
            } else {
                if let info = workspacePaths.sorted(by: { $1.key > $0.key }).first {
                    (path, application) = info
                    path = self.workspace.rootPath.appending(pathComponent: path)
                } else {
                    path = self.workspace.rootPath
                }
            }
            if !self.open(url: URL(fileURLWithPath: path), withApplication: application) {
                throw RuntimeError("Open Failed!")
            }
        }

    }
}

extension MBWorkspace {
    dynamic
    open var workspacePaths: [String: String] {
        return [:]
    }
}
