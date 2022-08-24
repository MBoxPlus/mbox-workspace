//
//  MBConfig.Feature+Export.swift
//  MBoxWorkspaceCore
//
//  Created by 詹迟晶 on 2021/12/28.
//  Copyright © 2021 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

public protocol MBConfigFeatureExportProtocol {
    var exportKeys: [String]? { get }
    var exportHash: [String: Any]? { get }
}

// MAKR: - Export Data
extension MBCodable {
    public func exportData() -> Any? {
        return self.toCodableObject()
    }
}

extension MBCodableObject {
    public func exportData() -> Any? {
        return self.dictionary.exportData()
    }
}

extension MBConfigFeatureExportProtocol {
    public func exportData() -> Any? {
        guard var data = self.exportHash else { return nil }
        let keys = self.exportKeys ?? Array(data.keys)
        data = data.filter {
            keys.contains($0.key) && !($0.value is NSNull)
        }
        return data.exportData()
    }
}

extension Array {
    public func exportData() -> Any? {
        return self.compactMap { item -> Any? in
            return MBoxWorkspaceCore.exportData(item)
        }
    }
}

extension Dictionary {
    public func exportData() -> Any? {
        return self.compactMapKeysAndValues { (key: Key, value: Any) -> (Key, Any)? in
            if let value = MBoxWorkspaceCore.exportData(value) {
                return (key, value)
            }
            return nil
        }
    }
}

func exportData(_ item: Any) -> Any? {
    if let item = item as? MBConfigFeatureExportProtocol {
        return item.exportData()
    }
    if let item = item as? [Any] {
        return item.exportData()
    }
    if let item = item as? [String: Any] {
        return item.exportData()
    }
    if let item = item as? MBCodableObject {
        return item.exportData()
    }
    if let item = item as? MBCodable {
        return item.exportData()
    }
    return item
}

// MARK: - Feature Export
extension MBConfig.Feature: MBConfigFeatureExportProtocol {

    dynamic
    public var exportKeys: [String]? {
        guard let ks = self.exportHash?.keys else { return nil }
        var keys = Array(ks)
        keys.removeAll("stash_hash")
        return keys
    }

    dynamic
    public var exportHash: [String: Any]? {
        return self.dictionary
    }

    public func export() throws -> String {
        guard let data = (self as MBConfigFeatureExportProtocol).exportData() as? MBCodable else { return "{}" }
        return try data.toString(coder: .json, sortedKeys: true, prettyPrinted: false)
    }

}
