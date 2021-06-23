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
import MBoxWorkspaceCore

public protocol MBCommanderStatus {
    static var supportedAPI: [MBCommander.Status.APIType] { get }
    static var title: String { get }
    static var showTitle: Bool { get }
    init(feature: MBConfig.Feature)
    var feature: MBConfig.Feature { set get }
    func textRow() throws -> Row?
    func textRows() throws -> [Row]?
    func APIData() throws -> Any?
    func plainData() throws -> [String]?
}

extension MBCommanderStatus {
    public static var showTitle: Bool { return true }
    public func textRow() throws -> Row? { return nil }
    public func textRows() throws -> [Row]? { return nil }
    public func APIData() throws -> Any?  { return nil }
    public func plainData() throws -> [String]?  { return nil }
}

extension MBCommander {
    open class Status: MBCommander {
        public enum APIType {
            case none
            case api
            case plain
        }

        open class override var description: String? {
            return "Show Status"
        }

        open class override var arguments: [Argument] {
            var arguments = super.arguments
            arguments << Argument("name", description: "Show Other Feature")
            return arguments
        }

        open override class var options: [Option] {
            var options = super.options
            options << Option("only", description: "Only show information.", valuesBlock: { return self.sections.map { $0.title } })
            return options
        }

        dynamic
        open override class var flags: [Flag] {
            var flags = super.flags
            flags << Flag("sync", description: "Sync config and repos")
            return flags
        }

        open override func setup() throws {
            self.only = (self.shiftOptions("only") ?? ["all"]).map { $0.lowercased() }
            self.sync = self.shiftFlag("sync", default: false)
            try super.setup()
            self.name = self.shiftArgument("name")
        }

        open var name: String?
        open var only: [String] = ["all"]
        open var sync: Bool = false

        open var sections: [MBCommanderStatus.Type] = []
        open var feature: MBConfig.Feature!

        dynamic
        public class var allSections: [MBCommanderStatus.Type] {
            return [Root.self, Feature.self, Repos.self, Git.self]
        }

        open class var sections: [MBCommanderStatus.Type] {
            let apiType: APIType
            switch UI.apiFormatter {
            case .none:
                apiType = .none
            case .plain:
                apiType = .plain
            default:
                apiType = .api
            }
            return self.allSections.filter {
                $0.supportedAPI.contains(apiType)
            }
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
            } else {
                self.feature = config.currentFeature
            }

            var sections = [MBCommanderStatus.Type]()
            let allSections = Self.sections
            for only in self.only {
                let only = only.lowercased()
                if only == "all" {
                    sections.append(contentsOf: allSections)
                } else if let section = allSections.first(where: { $0.title.lowercased() == only }) {
                    sections.append(section)
                }
            }
            for section in sections {
                if !self.sections.contains(where: { $0 == section }) {
                    self.sections.append(section)
                }
            }

            if UI.apiFormatter == .plain {
                if self.sections.count > 1 {
                    throw ArgumentError.conflict("It is not allowed with multiple sections when using `--api=plain`.")
                }
            }
        }

        // MARK: - Show status
        dynamic
        open override func run() throws {
            try super.run()
            if (self.sync) {
                try self.syncStatus()
            } else {
                try self.showStatus()
            }
        }

        open func showStatus() throws {
            switch UI.apiFormatter {
            case .none:
                try self.showText(sections)
            case .plain:
                if let section = sections.first {
                    try self.showPlain(section)
                }
            default:
                try self.showAPI(sections)
            }
        }
    }
}
