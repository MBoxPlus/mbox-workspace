//
//  Status+Feature.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2021/2/28.
//  Copyright © 2021 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxWorkspaceCore

extension MBCommander.Status {
    open class Feature: MBCommanderStatus {
        public static var supportedAPI: [APIType] {
            return [.none, .api, .plain]
        }

        public static var title: String {
            return "feature"
        }

        public var feature: MBConfig.Feature

        public required init(feature: MBConfig.Feature) {
            self.feature = feature
        }

        public func textRow() throws -> Row? {
            return Row(column: self.feature.name.ANSI(.yellow))
        }

        public func APIData() throws -> Any?  {
            return self.feature.name
        }

        public func plainData() throws -> [String]?  {
            return [self.feature.name]
        }

    }
}
