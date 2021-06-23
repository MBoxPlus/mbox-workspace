//
//  ImportTests.swift
//  MBoxWorkspaceTests
//
//  Created by 詹迟晶 on 2020/3/26.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Foundation
import Nimble
import MBoxCore
import MBoxWorkspaceCore

class ImportInFreeTests: MBoxUnitTests {

    func testExists() {
        copyRubyRepo()
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "master")]

        let hash = ["repos": [["url": MBoxWorkspaceTests.global.fixtureURLs["normal"], "last_branch": "master"]]]
        let cmd = try! MBCommander.Feature.Import(argv: ArgumentParser(arguments: [hash.toJSONString()!]))
        expect(try cmd.performAction()).toNot(throwError())
        expect(self.currentFeature.free).isTrue()
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "master")]
    }

    func testExistsButBranchDifferent() {
        copyRubyRepo()
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "master")]

        let hash = ["repos": [["url": MBoxWorkspaceTests.global.fixtureURLs["normal"], "last_branch": "develop"]]]
        let cmd = try! MBCommander.Feature.Import(argv: ArgumentParser(arguments: [hash.toJSONString()!]))
        expect(try cmd.performAction()).toNot(throwError())
        expect(self.currentFeature.free).isTrue()
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "develop")]
    }

    func testNoExists() {
        let hash = ["repos": [["url": MBoxWorkspaceTests.global.fixtureURLs["normal"], "last_branch": "develop"]]]
        let cmd = try! MBCommander.Feature.Import(argv: ArgumentParser(arguments: [hash.toJSONString()!]))
        expect(try cmd.performAction()).toNot(throwError())
        expect(self.currentFeature.free).isTrue()
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "develop")]
    }
}

