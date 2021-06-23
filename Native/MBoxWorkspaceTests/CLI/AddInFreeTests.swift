//
//  AddInFreeTests.swift
//  MBoxWorkspaceTests
//
//  Created by 詹迟晶 on 2019/12/18.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Nimble
import MBoxCore
import SwiftGit2
import MBoxWorkspaceCore

class AddInFreeTests: MBoxUnitTests {

    // MARK: - NAME/URL/PATH
    func testName() {
        let path = MBoxWorkspaceTests.global.fixturePath("normal")
        let cachePath = UI.workspace!.cachedReposDir.appending(pathComponent: "mbox-ruby@mbox")
        try? FileManager.default.createDirectory(atPath: cachePath.deletingLastPathComponent, withIntermediateDirectories: true, attributes: nil)
        try! FileManager.default.copyItem(atPath: path, toPath: cachePath)
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: ["mbox-ruby", "v1.0.0"]))
        expect { try cmd.performAction() }.toNot(throwError())
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "v1.0.0")]
    }

    func testAbsoluteLocalPath() {
        let path = MBoxWorkspaceTests.global.fixturePath("normal")
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [path, "master", "--mode=copy"]))
        expect { try cmd.performAction() }.toNot(throwError())
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "master")]
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
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "master")]
    }

    func testRemoteGitURL() {
        let url = MBoxWorkspaceTests.global.fixtureURLs["normal"]!
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [url, "master"]))
        expect { try cmd.performAction() }.toNot(throwError())
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "master")]
    }

    func testRemoteHTTPURL() {
        let url = "https://github.com/mboxplus/mbox-ruby.git"
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [url, "master"]))
        expect { try cmd.performAction() }.toNot(throwError())
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "master")]
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
        var path = MBoxWorkspaceTests.global.fixturePath("normal")
        try! FileManager.default.copyItem(atPath: path, toPath: path + "_worktree")
        path = path + "_worktree"
        let gitCMD = MBCMD(workingDirectory: path)
        gitCMD.exec("git checkout master")

        let relative = path.relativePath(from: self.rootPath)
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [relative, "v1.0.0", "--mode=worktree"]))
        expect { try cmd.performAction() }.toNot(throwError())
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "v1.0.0")]

        // 仓库在 Work 状态
        let workPath = self.currentFeature.repos.first?.workingPath
        expect(workPath).isNotNil()

        // 仓库分支正确
        let repo = try! Repository.at(URL(fileURLWithPath: workPath!)).get()
        expect { expect(try (repo.HEAD().get().oid) == repo.tag(named: "v1.0.0").get().oid) }.toNot(throwError())

        // 确保原始仓库不受影响
        let originRepo = try! Repository.at(URL(fileURLWithPath: path)).get()
        expect { expect(try originRepo.HEAD().get().shortName) == "master" }.toNot(throwError())
    }

    // MARK: - base branch
    func testWithTag() {
        let url = MBoxWorkspaceTests.global.fixtureURLs["normal"]!
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [url, "v1.0.0"]))
        expect { try cmd.performAction() }.toNot(throwError())
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "v1.0.0")]
    }

    func testWithCommit() {
        let url = MBoxWorkspaceTests.global.fixtureURLs["normal"]!
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [url, "4a47351ffd"]))
        expect { try cmd.performAction() }.toNot(throwError())
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "4a47351ffd")]
    }

    func testWithBranch() {
        let url = MBoxWorkspaceTests.global.fixtureURLs["normal"]!
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [url, "master"]))
        expect { try cmd.performAction() }.toNot(throwError())
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "master")]
    }

    // MARK: - add a repo which exist in working path, it is unexpected
    func testWorkingRepoWithUnexpectBranch() {
        let path = MBoxWorkspaceTests.global.fixturePath("normal")
        try! FileManager.default.copyItem(atPath: path, toPath: self.rootPath.appending(pathComponent: "mbox-ruby"))
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [path, "develop"]))
        expect { try cmd.performAction() }.toNot(throwError())
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "develop")]
    }

    func testWorkingRepoWithExpectBranch() {
        let path = MBoxWorkspaceTests.global.fixturePath("normal")
        try! FileManager.default.copyItem(atPath: path, toPath: self.rootPath.appending(pathComponent: "mbox-ruby"))
        let cmd = try! MBCommander.Add(argv: ArgumentParser(arguments: [path, "master"]))
        expect { try cmd.performAction() }.toNot(throwError())
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "master")]
    }
}
