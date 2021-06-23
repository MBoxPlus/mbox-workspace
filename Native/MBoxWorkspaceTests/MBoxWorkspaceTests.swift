//
//  MBoxWorkspaceTests.swift
//  MBoxWorkspaceTests
//
//  Created by Whirlwind on 2019/5/31.
//  Copyright © 2019 bytedance. All rights reserved.
//

import XCTest
import Nimble
import MBoxCore
import MBoxWorkspaceCore

@objc(MBoxWorkspaceTests)
public class MBoxWorkspaceTests: NSObject, XCTestObservation {
    public lazy var fixtureURLs: [String: String] = [
        "normal": "git@github.com:mboxplus/mbox-ruby.git",
        "normal2": "git@github.com:mboxplus/mbox-tos.git"
    ]
    public func fixturePath(_ name: String) -> String {
        return fixtureDirectory.appending(pathComponent: name)
    }

    public override init() {
        super.init()
        XCTestObservationCenter.shared.addTestObserver(self)
    }

    public lazy var temporaryDirectory: String = "\(NSTemporaryDirectory())MBoxTests/\(String.random(ofLength: 6))/Workspace"
    public lazy var fixtureDirectory: String = "\(temporaryDirectory)/fixtures"

    public static var global: MBoxWorkspaceTests!

    public func testBundleWillStart(_ testBundle: Bundle) {
        if self.bundle != testBundle { return }

        UI.verbose = true
        UI.section("Setup Environment, Using temporary directory: \(self.temporaryDirectory)") {
            try? FileManager.default.removeItem(atPath: self.temporaryDirectory)
            try! FileManager.default.createDirectory(atPath: self.fixtureDirectory, withIntermediateDirectories: true, attributes: nil)
            let cmd = MBCMD(workingDirectory: self.fixtureDirectory)
            for (name, url) in fixtureURLs {
                if !cmd.exec("git clone '\(url)' '\(name)'") {
                    assertionFailure("Git Clone Failed: \(url)")
                }
            }
        }
        Self.global = self
        // 初始化全局配置
        MBSetting.global.workspace.branchPrefix = "feature/"
    }

    public func testBundleDidFinish(_ testBundle: Bundle) {
        if self.bundle != testBundle { return }
        try? FileManager.default.removeItem(atPath: self.temporaryDirectory)
    }
}

extension MBWorkspace {
    public struct Status: Equatable {
        let name: String
        let current: String
        let target: String?
        init(name: String, current: String, target: String? = nil) {
            self.name = name
            self.current = current
            self.target = target
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.name == rhs.name && lhs.current == rhs.current && lhs.target == rhs.target
        }

    }
    public func status() -> [Status] {
        return config.currentFeature.repos.map { Status(name: $0.name, current: try! $0.git!.currentDescribe().value, target: $0.targetBranch) }
    }
}

extension MBCommander {
    public class func exec(_ args: [String]) throws {
        let cmd = try Self.init(argv: ArgumentParser(arguments: args))
        try cmd.performAction()
    }
}

class MBoxUnitTests: XCTestCase {

    lazy var rootPath: String = MBoxWorkspaceTests.global.temporaryDirectory.appending(pathComponent: .random(ofLength: 6))

    override func setUp() {
        UI.rootPath = self.rootPath
        try! FileManager.default.createDirectory(atPath: self.rootPath, withIntermediateDirectories: true, attributes: nil)
        FileManager.chdir(self.rootPath)
        exec(["init"])
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: rootPath)
    }

    func exec(_ cmd: [String], error: Error? = nil, file: FileString = #file, line: UInt = #line) {
        for package in MBPluginManager.shared.packages {
            package.mainClass = nil
            if !package.required {
                _ = MBPluginManager.shared.unload(package: package)
            }
        }
        let cmds = ["mbox"] + cmd + ["-v"]
        if let error = error {
            expect(try runCommander(cmds), file: file, line: line).to(throwError(error))
        } else {
            expect(try runCommander(cmds), file: file, line: line).toNot(throwError())
        }
    }

    var currentFeature: MBConfig.Feature {
        return UI.workspace!.config.currentFeature
    }

    func start(feature: String, args: [String] = [], error: Error, file: FileString = #file, line: UInt = #line) {
        exec(["feature", "start", feature] + args, error: error, file: file, line: line)
    }

    func start(feature: String, args: [String] = [], status: [MBWorkspace.Status], file: FileString = #file, line: UInt = #line) {
        exec(["feature", "start", feature] + args, file: file, line: line)
        expectFeature(name: feature, status: status, file: file, line: line)
    }

    func expectFeature(name: String, status: [MBWorkspace.Status], file: FileString = #file, line: UInt = #line) {
        expect(self.currentFeature.name, file: file, line: line) == name
        expect(UI.workspace!.status(), file: file, line: line) == status
        self.currentFeature.repos.forEach { repo in
            expect(repo.isWorking, file: file, line: line).isTrue()
        }
    }

    func copyRubyRepo(branch: String = "master", file: FileString = #file, line: UInt = #line) {
        let path = MBoxWorkspaceTests.global.fixturePath("normal")
        exec(["add", path, branch, "--mode=copy"], file: file, line: line)
        let status: MBWorkspace.Status
        if UI.workspace!.config.currentFeature.free {
            status = MBWorkspace.Status(name: "mbox-ruby", current: branch)
        } else {
            status = MBWorkspace.Status(name: "mbox-ruby", current: UI.workspace!.config.currentFeature.branchName!, target: branch)
        }
        expect(UI.workspace!.status().contains(status), file: file, line: line).isTrue()
    }

    func copyTOSRepo(branch: String = "master", file: FileString = #file, line: UInt = #line) {
        let path = MBoxWorkspaceTests.global.fixturePath("normal2")
        exec(["add", path, branch, "--mode=copy"], file: file, line: line)
        let status: MBWorkspace.Status
        if UI.workspace!.config.currentFeature.free {
            status = MBWorkspace.Status(name: "mbox-tos", current: branch)
        } else {
            status = MBWorkspace.Status(name: "mbox-tos", current: UI.workspace!.config.currentFeature.branchName!, target: branch)
        }
        expect(UI.workspace!.status().contains(status), file: file, line: line).isTrue()
    }

    func readLogFile() -> String {
        let logPath = UI.infoLogFilePath!
        return try! String(contentsOfFile: logPath)
    }
}
