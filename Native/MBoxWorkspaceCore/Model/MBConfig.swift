//
//  MBConfig.swift
//  MBoxCore
//
//  Created by Whirlwind on 2018/8/28.
//  Copyright © 2018 Bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import Then

public class MBConfig: MBCodableObject, MBJSONProtocol {

    public weak var workspace: MBWorkspace!

    public var freeFeature: MBConfig.Feature {
        return feature(withName: nil)!
    }

    public var currentFeature: MBConfig.Feature {
        return self.feature(withName: _currentFeatureName) ?? self.addFeature(Feature(name: _currentFeatureName))
    }

    public var lockFilePath: String {
        return self.filePath!.appending(pathExtension: "lock")
    }

    private var lockCounter: Int = 0
    public func lock() -> Bool {
        if lockCounter > 0 {
            lockCounter += 1
            return true
        }
        let path = self.lockFilePath
        if path.isExists { return false }
        if FileManager.default.createFile(atPath: path, contents: nil) {
            lockCounter = 1
            return true
        }
        return false
    }

    public func unlock(force: Bool = false) {
        if lockCounter > 0 {
            lockCounter -= 1
        }
        if force || lockCounter <= 0 {
            try? FileManager.default.removeItem(atPath: self.lockFilePath)
            lockCounter = 0
        }
    }

    public func feature(withName name: String?) -> MBConfig.Feature? {
        let name = name?.lowercased() == MBConfig.Feature.FreeMode.lowercased() ? "" : name
        if let feature = self.features[name?.lowercased() ?? ""] {
            return feature
        }
        if name == nil || name == "" {
            let feature = Feature(name: "")
            feature.config = self
            self.features[""] = feature
            return feature
        }
        return nil
    }

    @discardableResult
    public func addFeature(_ feature: MBConfig.Feature) -> MBConfig.Feature {
        if let exist = self.feature(withName: feature.name) {
            return exist
        }
        feature.stashHash = MBConfig.Feature.generateStashHash()
        feature.config = self
        feature.isNew = true
        self.features[feature.name.lowercased()] = feature
        return feature
    }

    public func removeFeature(_ name: String) {
        self.features.removeValue(forKey: name.lowercased())
    }

    // MARK: - JSON
    @Codable(key: "current_feature_name")
    private var _currentFeatureName: String = ""
    public var currentFeatureName: String {
        set {
            let value = newValue == MBConfig.Feature.FreeMode ? "" : newValue
            self._currentFeatureName = value
        }
        get {
            let name = self._currentFeatureName
            return name != "" ? name : MBConfig.Feature.FreeMode
        }
    }

    @Codable
    public var features: [String: MBConfig.Feature] = [:]

    @Codable
    public var version: String = "1.0"

    @Codable
    public var plugins: [String: String] = [:]

    public override func prepare(dictionary: [String: Any]) -> [String: Any] {
        var dictionary = super.prepare(dictionary: dictionary)
        if let features = dictionary["features"] as? [String: Any] {
            dictionary["features"] = features.compactMapValues { try? MBConfig.Feature.load(fromObject: $0).then {
                    $0.config = self
                }
            }
        }
        return dictionary
    }

    @discardableResult dynamic
    public func save() -> Bool {
        return (self as MBFileProtocol).save()
    }
}
