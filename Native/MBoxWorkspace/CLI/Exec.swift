//
//  Exec.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/8/5.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxWorkspaceCore

extension MBCommander {
    open class Exec: MBCommander {

        open class override var description: String? {
            return "Exec command line in MBox Environment"
        }

        open override class var options: [Option] {
            var options = super.options
            if !self.onlyRunInWorkspace {
                let values = { () -> [String] in
                    guard let workspace = UI.workspace else { return [] }
                    return workspace.config.currentFeature.repos.map { $0.name }
                }
                options << Option("repo", description: "Specify a repo, use this option multiple times to specify multiple repos.", valuesBlock: values)
                options << Option("no-repo", description: "Exclude a repo, use this option multiple times to exclude multiple repos.", valuesBlock: values)
            }
            return options
        }

        open override class func autocompletion(argv: ArgumentParser) -> [String] {
            return [self.autocompletionRedirect]
        }

        open override var allowRemainderArgs: Bool {
            return true
        }

        open override func setup() throws {
            self.inRepos = self.shiftOptions("repo")
            self.noRepos = self.shiftOptions("no-repo")
            self.requireSetupEnvironment = true
            try super.setup()
        }

        open class var onlyRunInWorkspace: Bool {
            return true
        }

        open var onlyRunInWorkspace: Bool {
            return Self.onlyRunInWorkspace
        }

        open var inRepos: [String]?
        open var noRepos: [String]?

        dynamic
        open override func run() throws {
            try super.run()
            let (cmd, args) = try self.setupCMD()
            let argument = self.argumentString(args: args)
            if !cmd.bin.isEmpty && !cmd.binExists {
                throw RuntimeError("command not found: \(cmd.bin)")
            }
            if self.onlyRunInWorkspace {
                UI.statusCode = self.runInWorkspace(cmd: cmd, args: argument)
            } else {
                let repos = self.reposToRun()
                if repos.isEmpty {
                    UI.log(info: "No repository to be run.")
                    return
                }
                for repo in repos {
                    UI.section("[\(repo)]") {
                        guard let workRepo = repo.workRepository else {
                            UI.log(verbose: "Repo `\(repo)` not exists!")
                            return
                        }
                        let v: Int32 = self.runInRepo(repo: workRepo, cmd: cmd, args: argument)
                        if v != 0 {
                            UI.statusCode = v
                        }
                        UI.log(verbose: "")
                    }
                }
            }
        }

        dynamic
        open func reposToRun() -> [MBConfig.Repo] {
            return self.filterRepos(repos: self.config.currentFeature.repos)
        }

        open func filterRepos(repos: [MBConfig.Repo]) -> [MBConfig.Repo] {
            if self.inRepos == nil && self.noRepos == nil { return repos }
            return repos.filter { repo -> Bool in
                return (self.inRepos?.any(matching: { repo.isName($0) }) ?? true) &&
                    !(self.noRepos?.any(matching: { repo.isName($0) }) ?? false)
            }
        }

        open func runInWorkspace(cmd: MBCMD, args: String, workingDirectory: String? = nil) -> Int32 {
            return cmd.exec(args, workingDirectory: workingDirectory ?? self.workspace.rootPath)
        }

        open func runInRepo(repo: MBWorkRepo, cmd: MBCMD, args: String) -> Int32 {
            return cmd.exec(args, workingDirectory: repo.path)
        }

        open override func help(_ desc: String? = nil) throws {
            if desc == nil,
                UI.apiFormatter == .none {
                argv.append(argument: self.helpOptionName)
                argv.rawArguments.append(self.helpOptionName)
                let cmd = try self.setupCMD()
                cmd.0.exec(self.argumentString(args: self.args))
                UI.log(info: "")
            }
            try super.help()
        }

        open var helpOptionName: String {
            return "--help"
        }

        dynamic
        open var cmd: MBCMD? {
            return nil
        }

        open var args: [String] {
            var args = [String]()
            for item in self.argv.remainder {
                for raw in self.argv.rawArguments {
                    if raw.hasPrefix(item) {
                        args.append(raw)
                        break
                    }
                }
            }
            return args
        }

        open func argumentString(args: [String]) -> String {
            return args.map { $0.quoted }.joined(separator: " ")
        }

        dynamic
        open func setupCMDMap() -> [String: MBCMD.Type] {
            return [:]
        }
        public lazy var CMDMap = self.setupCMDMap()

        dynamic
        open func setupCMD() throws -> (MBCMD, [String]) {
            var args = self.args
            var cmd = self.cmd
            if cmd == nil {
                if Self.self != Exec.self,
                   let klass = self.CMDMap[Self.fullName] {
                    cmd = klass.init()
                } else if args.count > 0 {
                    let bin = args.removeFirst()
                    let klass = self.CMDMap[bin] ?? MBCMD.self
                    cmd = klass.init()
                    if cmd!.bin.isEmpty {
                        cmd!.bin = bin
                    } else {
                        args.insert(bin, at: 0)
                    }
                } else {
                    cmd = MBCMD()
                }
            }
            cmd!.showOutput = true
            return (cmd!, args)
        }

        dynamic
        open override var canCancel: Bool {
            return true
        }

        open override func cancel() throws {
            try super.cancel()
        }
    }
}
