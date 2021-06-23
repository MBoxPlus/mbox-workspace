//
//  FreeTests.swift
//  MBoxWorkspaceTests
//
//  Created by 詹迟晶 on 2019/12/31.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import Nimble
import MBoxCore
import MBoxWorkspaceCore

class FreeTests: MBoxUnitTests {

    func testFromFree() {
        copyRubyRepo()
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "master")]

        let cmd = try! MBCommander.Feature.Free(argv: ArgumentParser())
        expect(try cmd.performAction()).toNot(throwError())
        expect(self.currentFeature.free).isTrue()
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "master")]
    }

    func testFromFeature() {
        copyRubyRepo()
        start(feature: "feature1", status: [MBWorkspace.Status(name: "mbox-ruby", current: "feature/feature1", target: "master")])
        copyTOSRepo()

        let cmd = try! MBCommander.Feature.Free(argv: ArgumentParser())
        expect(try cmd.performAction()).toNot(throwError())
        expect(self.currentFeature.free).isTrue()
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "master")]
    }
}
