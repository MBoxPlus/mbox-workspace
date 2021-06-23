//
//  FeatureMergeTests.swift
//  MBoxWorkspaceTests
//
//  Created by 詹迟晶 on 2020/1/3.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Nimble
import MBoxCore
import MBoxWorkspaceCore

class FeatureMergeTests: MBoxUnitTests {

    override func setUp() {
        super.setUp()
        copyRubyRepo()
        start(feature: "feature1", status: [MBWorkspace.Status(name: "mbox-ruby", current: "feature/feature1", target: "master")])
        start(feature: "feature2", status: [MBWorkspace.Status(name: "mbox-ruby", current: "feature/feature2", target: "master")])
        copyTOSRepo()
    }

    override class func tearDown() {
        let cmd = MBCMD()

        cmd.workingDirectory = UI.workspace?.cachedReposDir.appending(pathComponent: "mbox-ruby@mbox")
        if cmd.workingDirectory?.isExists == true {
            cmd.exec("git push origin :feature/feature1")
            cmd.exec("git push origin :feature/feature2")
        }

        cmd.workingDirectory = UI.workspace?.cachedReposDir.appending(pathComponent: "mbox-tos@mbox")
        if cmd.workingDirectory?.isExists == true {
            cmd.exec("git push origin :feature/feature1")
            cmd.exec("git push origin :feature/feature2")
        }

        super.tearDown()
    }

    func testInFree() {
        exec(["feature", "free"])
        copyTOSRepo(branch: "develop")
        expectFeature(name: "FreeMode",
                      status: [
                        MBWorkspace.Status(name: "mbox-ruby", current: "master"),
                        MBWorkspace.Status(name: "mbox-tos", current: "develop")])
        exec(["feature", "merge"])
        let logPath = UI.infoLogFilePath!
        let log = try! String(contentsOfFile: logPath)
        expect(log.contains("No repository to merge.")).isTrue()
    }
}
