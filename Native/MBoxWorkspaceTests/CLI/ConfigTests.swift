//
//  ConfigTests.swift
//  MBoxWorkspaceTests
//
//  Created by 詹迟晶 on 2020/1/3.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
import Nimble
import MBoxCore

class ConfigTests: MBoxUnitTests {

    override func setUp() {
        super.setUp()
        MBSetting.global.workspace.dictionary.removeAll()
    }

    func setupWorkspaceConfig(_ config: [String: Any]? = nil) {
        let path = self.rootPath.appending(pathComponent: ".mboxconfig")
        if let config = config {
            try! config.toJSONString()?.write(toFile: path, atomically: true, encoding: .utf8)
        } else if path.isExists {
            try! FileManager.default.removeItem(atPath: path)
        }
        UI.workspace!.userSetting = UI.workspace!.readSetting()
    }

    func testGetDefaultWorkspaceBranchPrefix() {
        setupWorkspaceConfig()
        exec(["config", "workspace.branch_prefix"])
        let log = readLogFile()
        expect(log).to(contain("workspace.branch_prefix: feature"))
    }

    func testGetCustomWorkspaceBranchPrefix() {
        setupWorkspaceConfig(["workspace": ["branch_prefix": "xxx"]])
        exec(["config", "workspace.branch_prefix"])
        let log = readLogFile()
        expect(log).to(contain("workspace.branch_prefix: xxx"))
    }

    func testGetWorkspaceCheckoutFromCommit() {
        setupWorkspaceConfig()
        exec(["config", "workspace.checkout_from_commit"])
        let log = readLogFile()
        expect(log).to(contain("workspace.checkout_from_commit: false"))
    }

    func testSetStringWorkspaceCheckoutFromCommit() {
        setupWorkspaceConfig()
        exec(["config", "workspace.branch_prefix", "xxxxx"])
        let log = readLogFile()
        expect(log).to(contain("workspace.branch_prefix: xxxxx"))
    }

    func testSetBoolWorkspaceCheckoutFromCommit() {
        setupWorkspaceConfig()
        exec(["config", "workspace.checkout_from_commit", "true"])
        let log = readLogFile()
        expect(log).to(contain("workspace.checkout_from_commit: true"))
    }

}
