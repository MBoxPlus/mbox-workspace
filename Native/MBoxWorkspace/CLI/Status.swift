//
//  Status.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/6/4.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Cocoa
import MBoxCore
import MBoxGit

public protocol MBCommanderStatus: MBCommanderEnv {
    init(feature: MBConfig.Feature)
    var feature: MBConfig.Feature { set get }
}

extension MBCommander {
    open class Status: Env {
        open class override var description: String? {
            return "Show Status"
        }

        open class override var arguments: [Argument] {
            var arguments = super.arguments
            arguments << Argument("name", description: "Show Other Feature")
            return arguments
        }

        dynamic
        open override class var flags: [Flag] {
            var flags = super.flags
            flags << Flag("sync", description: "Sync config and repos")
            return flags
        }

        open override func setup() throws {
            MBProcess.shared.showRootPath = false
            self.sync = self.shiftFlag("sync", default: false)
            try super.setup()
            self.name = self.shiftArgument("name")
        }

        open var name: String?
        open var sync: Bool = false

        dynamic
        open class override var allSections: [MBCommanderEnv.Type] {
            return [Root.self, Feature.self, Repos.self, Git.self]
        }

        open override func validate() throws {
            try super.validate()
            if self.sync,
               self.name != nil,
               self.config.currentFeature.name.lowercased() == self.name?.lowercased() {
                try help("Could not sync other feature.")
            }

            if let name = self.name {
                if let feature = config.feature(withName: self.name) {
                    self.feature = feature
                }
                try help("Could not find the feature named `\(name)`.")
            }
        }

        // MARK: - Show status
        dynamic
        open override func run() throws {
            try super.run()
        }
    }
}
