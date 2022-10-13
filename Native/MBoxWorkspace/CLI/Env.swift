//
//  Env.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/9/22.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

var kMBCommanderEnvFeatureKey: UInt8 = 0

extension MBCommander.Env {
    public var feature: MBConfig.Feature! {
        set {
            associateObject(base: self, key: &kMBCommanderEnvFeatureKey, value: newValue)
        }
        get {
            return associatedObject(base: self, key: &kMBCommanderEnvFeatureKey) {
                return self.config.currentFeature
            }
        }
    }

    @_dynamicReplacement(for: instance(for:))
    public func workspace_instance(for section: MBCommanderEnv.Type) -> MBCommanderEnv {
        if let section = section as? MBCommanderStatus.Type {
            return section.init(feature: self.feature)
        }
        return self.instance(for: section)
    }

    @_dynamicReplacement(for: allSections)
    public class var workspace_allSections: [MBCommanderEnv.Type] {
        return self.allSections + Status.allSections
    }
}
