//
//  RemoveFeatureTests.swift
//  MBoxWorkspaceTests
//
//  Created by 詹迟晶 on 2020/1/3.
//  Copyright © 2020 bytedance. All rights reserved.
//

import Nimble
import MBoxCore
import MBoxWorkspaceCore

class RemoveFeatureTests: MBoxUnitTests {

    override func setUp() {
        super.setUp()
        copyRubyRepo()
        start(feature: "feature1", status: [MBWorkspace.Status(name: "mbox-ruby", current: "feature/feature1", target: "master")])
        start(feature: "feature2", status: [MBWorkspace.Status(name: "mbox-ruby", current: "feature/feature2", target: "master")])
        copyTOSRepo()
    }

    func testSimple() {
        expect(UI.workspace?.config.features["feature1"]).isNotNil()
        exec(["feature", "remove", "feature1"])
        expect(UI.workspace?.config.features["feature1"]).isNil()

        // RuntimeError: 不能删除当前 Feature
        exec(["feature", "remove", "feature2"], error: UserError("Could not remove current feature."))

        // RuntimeError: 找不到 Feature
        exec(["feature", "remove", "feature_nonexist"], error: UserError("Could not find feature named `feature_nonexist`."))

        // RuntimeError: 必须要有 Feature Name 参数
        exec(["feature", "remove"], error: ArgumentError.invalidCommand("Need a feature name"))
    }

    func testAll() {
        exec(["feature", "remove", "--all"])
        expect(UI.workspace?.config.features["feature1"]).isNil()
        expect(UI.workspace?.config.features["feature2"]).isNotNil()
        expect(self.currentFeature.name) == "feature2"
    }

    func testIncludeRepo() {
        start(feature: "feature1", status: [MBWorkspace.Status(name: "mbox-ruby", current: "feature/feature1", target: "master")])
        let repo = MBConfig.Repo.find(name: "mbox-tos", in: UI.workspace!)
        expect(repo?.cachePath).isNotNil()
        expect(repo?.isCache) == true
        exec(["feature", "remove", "feature2", "--include-repo"])
        expect(MBConfig.Repo.find(name: "mbox-tos", in: UI.workspace!)).isNil()
        expectFeature(name: "feature1", status: [MBWorkspace.Status(name: "mbox-ruby", current: "feature/feature1", target: "master")])
    }
}
