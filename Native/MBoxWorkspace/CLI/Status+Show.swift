//
//  Status+Show.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2021/2/28.
//  Copyright © 2021 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBCommander.Status {
    // MARK: - API
    public func showAPI(_ sections: [MBCommanderStatus.Type]) throws {
        var api = [String: Any]()
        for section in sections {
            let obj = section.init(feature: self.feature)
            guard let value = try obj.APIData() else {
                continue
            }
            api[section.title] = value
        }
        UI.log(api: api)
    }

    // MARK: - Text
    public func outputSection(_ section: MBCommanderStatus.Type, row: Row) {
        let line = formatTable([row]).first!.trimmed
        if section.showTitle {
            let title = section.title.convertCamelCased()
            UI.log(info: "[\(title)]: \(line)")
        } else {
            UI.log(info: line)
        }
    }

    public func outputSection(_ section: MBCommanderStatus.Type, rows: [Row]) {
        if section.showTitle {
            let title = section.title.convertCamelCased()
            UI.log(info: "[\(title)]:")
        }

        for i in formatTable(rows) {
            UI.log(info: i)
        }
    }

    public func showText(_ sections: [MBCommanderStatus.Type]) throws {
        for (index, section) in sections.enumerated() {
            let obj = section.init(feature: self.feature)
            if let row = try obj.textRow() {
                outputSection(section, row: row)
            } else if let rows = try obj.textRows(), rows.count > 0 {
                outputSection(section, rows: rows)
            } else {
                continue
            }
            if index < sections.count - 1 {
                UI.log(info: "")
            }
        }
    }

    // MARK: - Plain
    public func showPlain(_ section: MBCommanderStatus.Type) throws {
        let obj = section.init(feature: self.feature)
        guard let value = try obj.plainData() else {
            return
        }
        UI.log(api: value)
    }
}
