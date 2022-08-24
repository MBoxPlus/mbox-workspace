//
//  Init.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/7/9.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

extension MBCommander {
    open class Init: MBCommander {
        open class override var description: String? {
            return "Init Workspace"
        }

        open class override func shouldShowInHelp() -> Bool {
            return MBProcess.shared.workspace == nil
        }

        open override class var options: [Option] {
            var options = super.options
            options << Option("plugin", description: "Config the plugin. It could be used many times to config more plugins.")
            options << Option("name", description: "To set the new MBox workspace (folder) name.")
            return options
        }

        open override class var arguments: [Argument] {
            var args = super.arguments
            args << Argument("plugin_group", description: "A plugin set. Available: \(MBWorkspace.pluginGroups.keys.sorted().joined(separator: "/"))", required: false, plural: true)
            return args
        }

        open override class func autocompletion(argv: ArgumentParser) -> [String] {
            var completions = super.autocompletion(argv: argv)
            completions.append(contentsOf: MBWorkspace.pluginGroups.keys)
            return completions
        }

        open override func setup() throws {
            if MBProcess.shared.rootPath != FileManager.pwd {
                UI.log(info: "[\(MBProcess.shared.rootPath)]\n", pip: .ERR)
            }
            try super.setup()

            self.plugins = self.shiftOptions("plugin") ?? []
            
            self.name = self.shiftOption("name")

            let groups = self.shiftArguments("plugin_group")
            if !groups.isEmpty {
                for group in groups {
                    guard let plugins = MBWorkspace.pluginGroups[group.lowercased()] else {
                        throw ArgumentError.invalidValue(value: group, argument: "PLUGIN_GROUP")
                    }
                    self.plugins.append(contentsOf: plugins)
                }
                self.groups = groups
            }
            MBProcess.shared.requireSetupLauncher = false
        }

        var plugins: [String] = []
        var groups: [String] = ["stable"]
        var name: String?

        open override func validate() throws {
            try super.validate()
            if let name = self.name {
                try UI.section("Use `\(name)` to create MBox workspace folder") {
                    let newPath = MBProcess.shared.rootPath.appending(pathComponent: name)
                    try FileManager.default.createDirectory(atPath: newPath, withIntermediateDirectories: true, attributes: nil)
                    MBProcess.shared.rootPath = newPath
                }
            }
            if MBProcess.shared.rootPath == "/" {
                throw UserError("Could not init a mbox at System Root Directory!")
            }
            if MBProcess.shared.rootPath.realpath.lowercased() == FileManager.home.realpath.lowercased() {
                throw UserError("Could not init a mbox at Home Root Directory!")
            }
            if let path = MBProcess.shared.workspace?.rootPath {
                throw UserError("Could not init a mbox at `\(MBProcess.shared.rootPath)`, \nthere is a mbox at `\(path)`.")
            }
            let cmd = MBCMD()
            if cmd.exec("git rev-parse --show-toplevel") {
                throw UserError("Could not init a mbox in a git repository: `\(cmd.outputString)`")
            }
        }

        open override func run() throws {
            try super.run()

            MBProcess.shared.workspace = try MBWorkspace.create(MBProcess.shared.rootPath, plugins: plugins)
            UI.log(info: "Init mbox workspace success.")

            MBPluginManager.shared.tryLoadWorkspace()
            MBProcess.shared.reloadPlugins()
            try self.setupLauncher()
        }
    }
}
