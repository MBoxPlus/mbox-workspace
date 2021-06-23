//
//  RemoveTests.swift
//  MBoxWorkspaceTests
//
//  Created by 詹迟晶 on 2019/12/31.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Nimble
import MBoxCore
import MBoxWorkspaceCore

class RemoveTests: MBoxUnitTests {

    func testSimple() {
        copyRubyRepo()

        let remove = try! MBCommander.Remove(argv: ArgumentParser(arguments: ["mbox-ruby"]))
        try! remove.performAction()
        expect(UI.workspace!.status()) == []
    }

    func testIncludeRepo() {
        copyRubyRepo()

        let remove = try! MBCommander.Remove(argv: ArgumentParser(arguments: ["mbox-ruby", "--include-repo"]))
        try! remove.performAction()
        expect(UI.workspace!.status()) == []
        let cacheDir = UI.workspace!.cachedReposDir
        expect(try FileManager.default.contentsOfDirectory(atPath: cacheDir)) == []
    }

    func testForce() {
        copyRubyRepo()

        try! FileManager.default.removeItem(atPath: "mbox-ruby/Native")
        let remove1 = try! MBCommander.Remove(argv: ArgumentParser(arguments: ["mbox-ruby"]))
        expect(try remove1.performAction()).to(throwError())
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "master")]

        let remove2 = try! MBCommander.Remove(argv: ArgumentParser(arguments: ["mbox-ruby", "--force"]))
        expect(try remove2.performAction()).notTo(throwError())
        expect(UI.workspace!.status()) == []
    }

    func testMulti() {
        copyRubyRepo()
        copyTOSRepo()

        let remove2 = try! MBCommander.Remove(argv: ArgumentParser(arguments: ["mbox-ruby", "mbox-tos"]))
        expect(try remove2.performAction()).notTo(throwError())
        expect(UI.workspace!.status()) == []
    }

    func testMultiForce() {
        copyRubyRepo()
        copyTOSRepo()

        try! FileManager.default.removeItem(atPath: "mbox-ruby/Native")
        let remove1 = try! MBCommander.Remove(argv: ArgumentParser(arguments: ["mbox-ruby", "mbox-tos"]))
        expect(try remove1.performAction()).to(throwError())
        expect(UI.workspace!.status()) == [MBWorkspace.Status(name: "mbox-ruby", current: "master"), MBWorkspace.Status(name: "mbox-tos", current: "master")]

        let remove2 = try! MBCommander.Remove(argv: ArgumentParser(arguments: ["mbox-ruby", "mbox-tos", "--force"]))
        expect(try remove2.performAction()).notTo(throwError())
        expect(UI.workspace!.status()) == []
    }

    func testMultiIncludeRepo() {
        copyRubyRepo()
        copyTOSRepo()

        let remove = try! MBCommander.Remove(argv: ArgumentParser(arguments: ["mbox-ruby", "mbox-tos", "--include-repo"]))
        try! remove.performAction()
        expect(UI.workspace!.status()) == []
        let cacheDir = UI.workspace!.cachedReposDir
        expect(try FileManager.default.contentsOfDirectory(atPath: cacheDir)) == []
    }

    func testAll() {
        copyRubyRepo()
        copyTOSRepo()

        let remove = try! MBCommander.Remove(argv: ArgumentParser(arguments: ["--all"]))
        try! remove.performAction()
        expect(UI.workspace!.status()) == []
    }

    func testAllIncludeRepo() {
        copyRubyRepo()
        copyTOSRepo()

        let remove = try! MBCommander.Remove(argv: ArgumentParser(arguments: ["--all", "--include-repo"]))
        try! remove.performAction()
        expect(UI.workspace!.status()) == []
        let cacheDir = UI.workspace!.cachedReposDir
        expect(try FileManager.default.contentsOfDirectory(atPath: cacheDir)) == []
    }
}
