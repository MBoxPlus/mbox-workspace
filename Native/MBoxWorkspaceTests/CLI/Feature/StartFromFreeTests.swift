//
//  StartTests.swift
//  MBoxWorkspaceTests
//
//  Created by 詹迟晶 on 2019/12/31.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Nimble
import MBoxCore
import MBoxWorkspaceCore
import SwiftGit2

class StartFromFreeTests: MBoxUnitTests {

    override func setUp() {
        super.setUp()
        copyRubyRepo()
    }

    func testSimple() {
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "master")]

        start(feature: "feature1", status: [MBWorkspace.Status(name: "mbox-ruby", current: "feature/feature1", target: "master")])
    }

    func testClear() {
        start(feature: "feature2", args: ["--clear"], status: [])
    }

    func testPrefix() {
        start(feature: "feature2", args: ["--prefix", "custom"], status: [MBWorkspace.Status(name: "mbox-ruby", current: "custom/feature2", target: "master")])

        // 读取全局配置
        UI.workspace?.userSetting.workspace.branchPrefix = "workspace"
        expect(UI.workspace?.userSetting.workspace.branchPrefix) == "workspace"
        UI.workspace?.userSetting.save()
        start(feature: "feature3", status: [MBWorkspace.Status(name: "mbox-ruby", current: "workspace/feature3", target: "master")])

        // 覆盖全局配置
        start(feature: "feature4", args: ["--prefix", "custom2"], status: [MBWorkspace.Status(name: "mbox-ruby", current: "custom2/feature4", target: "master")])
    }

    func testRepos() {
        // ArgumentError: 不允许 --clear 和 --repos 同时使用
        start(feature: "feature2", args: ["--clear", "--repos", "{\"mbox-ruby\":\"master\"}"], error: ArgumentError.conflict("`--clear` and `--repos` could NOT used at same time."))

        start(feature: "feature2",
              args: ["--repos", "{\"mbox-ruby\":\"develop\"}"],
              status: [MBWorkspace.Status(name: "mbox-ruby", current: "feature/feature2", target: "develop")])

        // UserError: 添加不存在的 repo
        start(feature: "feature3",
              args: ["--repos", "{\"mbox-ruby\":\"develop\", \"mbox-ruby2\":\"develop\"}"],
              error: UserError("The repos are not found in current feature: mbox-ruby2"))
    }

    func testKeepChanges() {
        let repo = self.currentFeature.findRepo(name: "mbox-ruby")!
        // Unstaged
        try! "".write(toFile: repo.path!.appending(pathComponent: "untrack.txt"), atomically: true, encoding: .utf8)
        try! FileManager.default.removeItem(atPath: repo.path!.appending(pathComponent: "manifest.yml"))
        try! "xxx".write(toFile: repo.path!.appending(pathComponent: "Native/Podfile.rb"), atomically: true, encoding: .utf8)

        // Staged
        try! "".write(toFile: repo.path!.appending(pathComponent: "add.txt"), atomically: true, encoding: .utf8)
        let cmd = MBCMD()
        cmd.exec("git add -- add.txt", workingDirectory: repo.path)
        try! FileManager.default.removeItem(atPath: repo.path!.appending(pathComponent: "Native/Basic.xcconfig"))
        cmd.exec("git add -- Native/Basic.xcconfig", workingDirectory: repo.path)
        try! "xxx".write(toFile: repo.path!.appending(pathComponent: "Native/MBoxRuby.podspec"), atomically: true, encoding: .utf8)
        cmd.exec("git add -- Native/MBoxRuby.podspec", workingDirectory: repo.path)

        start(feature: "feature2",
              args: ["--keep-changes"],
              status: [MBWorkspace.Status(name: "mbox-ruby", current: "feature/feature2", target: "master")])

        let status = repo.git!.status()
        expect(status.count) == 6

        let untracked = status.first { $0.status == .workTreeNew }
        let deleted = status.first { $0.status == .workTreeDeleted }
        let modified = status.first { $0.status == .workTreeModified }
        expect(untracked?.indexToWorkDir?.newFile?.path) == "untrack.txt"
        expect(deleted?.indexToWorkDir?.oldFile?.path) == "manifest.yml"
        expect(modified?.indexToWorkDir?.newFile?.path) == "Native/Podfile.rb"

        let newStaged = status.first { $0.status == .indexNew }
        let deletedStaged = status.first { $0.status == .indexDeleted }
        let modifiedStaged = status.first { $0.status == .indexModified }
        expect(newStaged?.headToIndex?.newFile?.path) == "add.txt"
        expect(deletedStaged?.headToIndex?.oldFile?.path) == "Native/Basic.xcconfig"
        expect(modifiedStaged?.headToIndex?.newFile?.path) == "Native/MBoxRuby.podspec"
    }

    func testPull() {
        let repo = self.currentFeature.findRepo(name: "mbox-ruby")!
        var cmd = MBCMD(workingDirectory: repo.path!)
        cmd.exec("git checkout -b feature/unit_test_tmp master")
        cmd.exec("git push origin feature/unit_test_tmp -u")
        cmd.exec("git checkout master")
        cmd.exec("git branch -f feature/unit_test_tmp 0e1f8de7dd022909e37cf486ac0e9e461f2c4f27")

        start(feature: "unit_test_tmp",
              status: [MBWorkspace.Status(name: "mbox-ruby", current: "feature/unit_test_tmp", target: "master")])

        expect(repo.git!.currentCommit) == "0e1f8de7dd022909e37cf486ac0e9e461f2c4f27"

        exec(["feature", "free"])
        start(feature: "unit_test_tmp",
              args: ["--pull"],
              status: [MBWorkspace.Status(name: "mbox-ruby", current: "feature/unit_test_tmp", target: "master")])

        let remoteCommit = try! repo.git?.commit(for: .branch("origin/master"))
        expect(repo.git!.currentCommit) == remoteCommit
        cmd = MBCMD(workingDirectory: repo.path!)
        cmd.exec("git push origin :feature/unit_test_tmp")
    }

    func testCheckoutFromRemote() {
        let repo = self.currentFeature.findRepo(name: "mbox-ruby")!
        var cmd = MBCMD(workingDirectory: repo.path!)
        cmd.exec("git checkout develop")
        cmd.exec("git branch -f master 0e1f8de")
        cmd.exec("git checkout master")

        start(feature: "feature2",
              status: [MBWorkspace.Status(name: "mbox-ruby", current: "feature/feature2", target: "master")])

        expect(repo.git!.currentCommit) == "0e1f8de7dd022909e37cf486ac0e9e461f2c4f27"

        start(feature: "feature3",
              args: ["--checkout-from-remote"],
              status: [MBWorkspace.Status(name: "mbox-ruby", current: "feature/feature3", target: "master")])

        let remoteCommit = try! repo.git?.commit(for: .branch("origin/master"))
        cmd = MBCMD(workingDirectory: repo.path!)
        expect(repo.git!.currentCommit) == remoteCommit
    }
}

