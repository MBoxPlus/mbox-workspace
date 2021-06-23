//
//  AddInFeatureTests.swift
//  MBoxWorkspaceTests
//
//  Created by 詹迟晶 on 2019/12/26.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Nimble
import MBoxCore
import SwiftGit2
import MBoxWorkspaceCore

class AddInFeatureTests: MBoxUnitTests {

    let featureName = "feature_0106"
    override func setUp() {
        super.setUp()
        start(feature: featureName, status: [])
    }

    // MARK: - NAME/URL/PATH
    func testName() {
        let path = MBoxWorkspaceTests.global.fixturePath("normal")
        let cachePath = UI.workspace!.cachedReposDir.appending(pathComponent: "mbox-ruby@mbox")
        try? FileManager.default.createDirectory(atPath: cachePath.deletingLastPathComponent, withIntermediateDirectories: true, attributes: nil)
        try! FileManager.default.copyItem(atPath: path, toPath: cachePath)
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: ["mbox-ruby", "v1.0.0"]))
        expect { try cmd.performAction() }.to(throwError(UserError("[mbox-ruby] Could not find the target branch `v1.0.0`")))
    }

    func testAbsoluteLocalPath() {
        let path = MBoxWorkspaceTests.global.fixturePath("normal")
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [path, "master", "--mode=copy"]))
        expect { try cmd.performAction() }.toNot(throwError())
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "feature/\(featureName)", target: "master")]
    }

    func testInvalidLocalPath() {
        let path = MBoxWorkspaceTests.global.fixturePath("non-exists")
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [path, "master", "--mode=copy"]))
        expect { try cmd.performAction() }.to(throwError())
    }

    func testRelativeLocalPath() {
        let path = MBoxWorkspaceTests.global.fixturePath("normal")
        let relative = path.relativePath(from: self.rootPath)
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [relative, "master", "--mode=copy"]))
        expect { try cmd.performAction() }.toNot(throwError())
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "feature/\(featureName)", target: "master")]
    }

    func testRemoteGitURL() {
        let url = MBoxWorkspaceTests.global.fixtureURLs["normal"]!
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [url, "master"]))
        expect { try cmd.performAction() }.toNot(throwError())
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "feature/\(featureName)", target: "master")]
    }

    func testRemoteInvalidURL() {
        let url = "git@github.com:mboxplus/invalid.git"
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [url, "master"]))
        expect { try cmd.performAction() }.to(throwError())
    }

    // MARK: - local path mode
    func testCopyPath() {
        let path = MBoxWorkspaceTests.global.fixturePath("normal")
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [path, "master", "--mode=copy"]))
        expect { try cmd.performAction() }.toNot(throwError())

        expect(path.isExists).isTrue()
        if let repo = self.currentFeature.findRepo(name: "mbox-ruby") {
            expect(repo.workingPath.isExists).isTrue()
        } else {
            fail("Repo not in working!")
        }
    }

    func testMovePath() {
        let path = MBoxWorkspaceTests.global.fixturePath("normal")
        let path2 = "\(path)_tmp"
        try! FileManager.default.copyItem(atPath: path, toPath: path2)
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [path2, "master", "--mode=move"]))
        expect { try cmd.performAction() }.toNot(throwError())

        expect(path2.isExists).isFalse()
        if let repo = self.currentFeature.findRepo(name: "mbox-ruby") {
            expect(repo.workingPath.isExists).isTrue()
        } else {
            fail("Repo not in working!")
        }
    }

    func testWorktreePath() {
        let path = MBoxWorkspaceTests.global.fixturePath("normal")
        let relative = path.relativePath(from: self.rootPath)
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [relative, "master", "--mode=worktree"]))
        expect { try cmd.performAction() }.toNot(throwError())
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "feature/\(featureName)", target: "master")]

        // 仓库在 Work 状态
        let workPath = self.currentFeature.repos.first?.workingPath
        expect(workPath).isNotNil()

        // 仓库分支正确
        let repo = try! Repository.at(URL(fileURLWithPath: workPath!)).get()
        expect { expect(try (repo.HEAD().get().shortName) == "feature/\(self.featureName)") }.toNot(throwError())

        // 确保原始仓库不受影响
        let originRepo = try! Repository.at(URL(fileURLWithPath: path)).get()
        expect { expect(try (originRepo.HEAD().get().shortName) == "master") }.toNot(throwError())
    }

    // MARK: - base branch
    func testWithExistTag() {
        let url = MBoxWorkspaceTests.global.fixtureURLs["normal"]!
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [url, "master", "v1.0.0"]))
        expect { try cmd.performAction() }.toNot(throwError())
    }

    func testWithNoExistTag() {
        let error = UserError("Could not find the unknown type `v0.0.0`")

        let url = MBoxWorkspaceTests.global.fixtureURLs["normal"]!
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [url, "master", "v0.0.0"]))
        expect { try cmd.performAction() }.to(throwError(error))
    }

    func testWithExistCommit() {
        let url = MBoxWorkspaceTests.global.fixtureURLs["normal"]!
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [url, "master", "4a47351ffd"]))
        expect { try cmd.performAction() }.toNot(throwError())
    }

    func testWithNoExistCommit() {
        let error = UserError("Could not find the unknown type `0000000d`")

        let url = MBoxWorkspaceTests.global.fixtureURLs["normal"]!
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [url, "master", "0000000d"]))
        expect { try cmd.performAction() }.to(throwError(error))
    }

    func testWithBranch() {
        let url = MBoxWorkspaceTests.global.fixtureURLs["normal"]!
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [url, "master"]))
        expect { try cmd.performAction() }.toNot(throwError())
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "feature/\(featureName)", target: "master")]
    }

    class AddInFeatureMock: MBCommander.Add {
        
    }
    // MARK: - checkout from commit
    func testCheckoutFromCommit() {

    }
}

