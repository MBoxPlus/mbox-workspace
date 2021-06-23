//
//  ImportInFeature.swift
//  MBoxWorkspaceTests
//
//  Created by 詹迟晶 on 2020/3/26.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
import Nimble
import MBoxCore
import MBoxWorkspaceCore

class ImportInFeatureTests: MBoxUnitTests {

    override func setUp() {
        super.setUp()
        start(feature: "feature1", status: [])
    }

    func testMissingBranch() {
        copyRubyRepo()

        let hash: [String: Any] = [
            "name": "feature1",
            "repos": [
                ["url": MBoxWorkspaceTests.global.fixtureURLs["normal"],
                 "last_branch": "master"]
            ]
        ]
        let cmd = try! MBCommander.Feature.Import(argv: ArgumentParser(arguments: [hash.toJSONString()!]))
        let error = UserError("There is not a `target_branch`/`base_branch` in the repo `mbox-ruby`")
        expect(try cmd.performAction()).to(throwError(error))
    }

    func testMissingBaseBranch() {
        copyRubyRepo()

        let hash: [String: Any] = [
            "name": "feature1",
            "repos": [
                ["url": MBoxWorkspaceTests.global.fixtureURLs["normal"],
                 "last_branch": "master",
                 "target_branch": "master"]
            ]
        ]
        let cmd = try! MBCommander.Feature.Import(argv: ArgumentParser(arguments: [hash.toJSONString()!]))
        expect(try cmd.performAction()).toNot(throwError())
    }

    func testMissingTargetBranch() {
        copyRubyRepo()

        let hash: [String: Any] = [
            "name": "feature1",
            "repos": [
                ["url": MBoxWorkspaceTests.global.fixtureURLs["normal"],
                 "last_branch": "master",
                 "base_branch": "master",
                 "base_type": "branch"]
            ]
        ]
        let cmd = try! MBCommander.Feature.Import(argv: ArgumentParser(arguments: [hash.toJSONString()!]))
        expect(try cmd.performAction()).toNot(throwError())
    }

    func testImportFeature2() {
        copyRubyRepo()
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "feature/feature1", target: "master")]

        let hash: [String: Any] = [
            "branch_prefix": "feature/",
            "name": "feature2",
            "repos": [
                ["url": MBoxWorkspaceTests.global.fixtureURLs["normal"],
                 "last_branch": "master",
                 "base_branch": "master",
                 "base_type": "branch"],
                ["url": MBoxWorkspaceTests.global.fixtureURLs["normal2"],
                 "target_branch": "master"]
            ]
        ]
        let cmd = try! MBCommander.Feature.Import(argv: ArgumentParser(arguments: [hash.toJSONString()!]))
        expect(try cmd.performAction()).toNot(throwError())
        expect(self.currentFeature.name) == "feature2"
        expect(UI.workspace!.status()) == [
            MBWorkspace.Status(name: "mbox-ruby", current: "master", target: "master"),
            MBWorkspace.Status(name: "mbox-tos", current: "feature/feature2", target: "master"),
        ]
    }

}


