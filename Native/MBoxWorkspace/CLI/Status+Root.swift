//
//  Status+Root.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2021/3/2.
//  Copyright © 2021 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

extension MBCommander.Status {
    open class Root: MBCommanderStatus {
        public static var supportedAPI: [APIType] {
            return [.api, .plain, .none]
        }

        public static var title: String {
            return "root"
        }

        public var feature: MBConfig.Feature

        public required init() {
            fatalError()
        }

        public required init(feature: MBConfig.Feature) {
            self.feature = feature
        }

        public func APIData() throws -> Any?  {
            return MBProcess.shared.workspace?.rootPath
        }

        public func plainData() throws -> [String]?  {
            return [MBProcess.shared.workspace!.rootPath]
        }

        public func textRow() throws -> Row? {
            return Row(column: MBProcess.shared.workspace!.rootPath)
        }
    }
}
