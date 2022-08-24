//
//  MBRepo.swift
//  MBoxWorkspaceCore
//
//  Created by Whirlwind on 2021/3/17.
//  Copyright © 2021 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit
import SwiftGit2

open class MBRepo {
    public enum Mode {
        case copy
        case move
        case worktree
        case unknown
        public static func mode(for name: String) -> Mode {
            switch name.lowercased().first {
            case "c":
                return .copy
            case "m":
                return .move
            case "w":
                return .worktree
            default:
                return .unknown
            }
        }
    }

    open var workspace: MBWorkspace! { return MBProcess.shared.workspace! }

    init?(path: String) {
        guard path.isDirectory else {
            return nil
        }
        self.path = path
    }

    open var name: String {
        return self.path.lastPathComponent
    }

    open var path: String {
        didSet {
            self.git = try? GitHelper(path: self.path)
        }
    }

    public lazy var git: GitHelper? = {
        do {
            return try GitHelper(path: self.path)
        } catch {
            UI.log(error: error.localizedDescription)
            return nil
        }
    }()
    public var url: String? {
        return self.git?.url
    }
    public var gitURL: MBGitURL? {
        if let url = self.url {
            return MBGitURL(url)
        }
        return nil
    }

    public func includeGitConfig() throws {
        guard let git = self.git else { return }
        try UI.log(verbose: "Inject workspace config file into `\(self.name)`") {
            var workspaceConfigPath = self.workspace.gitConfigPath
            if let repoConfigPath = git.configPath?.deletingLastPathComponent {
                workspaceConfigPath = workspaceConfigPath.relativePath(from: repoConfigPath)
            }
            try git.includeConfig(workspaceConfigPath)
        }
    }

    public func resetGit() throws {
        self.git = try GitHelper(path: self.path)
    }

    // MARK: - Package Name
    dynamic
    open func fetchPackageNames() -> [String] {
        var names = [self.name]
        let name = path.lastPathComponent
        if let index = name.lastIndex(of: "@") {
            names << String(name[..<index])
        } else {
            names << name
        }
        if let url = self.url, let gitURL = MBGitURL(url) {
            names << gitURL.project
        }
        return names
    }

    open lazy var packageNames: [String] = {
        return self.fetchPackageNames().withoutDuplicates()
    }()

    open func isName(_ name: String, owner: String? = nil) -> Bool {
        let name = name.lowercased()
        for packageName in self.packageNames {
            if packageName.lowercased() == name {
                return true
            }
        }
        return false
    }
}

extension MBRepo: CustomStringConvertible {
    public var description: String {
        return self.name
    }
}

extension MBRepo: Hashable {
    public static func == (lhs: MBRepo, rhs: MBRepo) -> Bool {
        return lhs.path == rhs.path
    }

    public func hash(into hasher: inout Hasher) {
        self.path.hash(into: &hasher)
    }
}
