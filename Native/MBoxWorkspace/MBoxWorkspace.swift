//
//  MBoxWorkspace.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2019/6/13.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Cocoa
import MBoxCore
import MBoxWorkspaceCore

@objc(MBoxWorkspace)
open class MBoxWorkspace: NSObject, MBWorkspacePluginProtocol {
    public func enablePlugin(workspace: MBWorkspace, from version: String?) throws {
        try workspace.setupGitConfig()
        for repo in workspace.config.currentFeature.repos {
            try? repo.workRepository?.includeGitConfig()
        }
    }

    public func disablePlugin(workspace: MBWorkspace) throws {

    }

    public func registerCommanders() {
        MBCommanderGroup.shared.addCommand(MBCommander.Go.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Status.self)
        MBCommanderGroup.shared.addCommand(MBCommander.New.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Add.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Remove.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Merge.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Feature.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Feature.Free.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Feature.Start.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Feature.Finish.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Feature.Remove.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Feature.Import.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Feature.Export.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Feature.List.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Feature.FeatureMerge.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Feature.Clean.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Exec.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Fork.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Tower.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Stree.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Git.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Repo.self)
        MBCommanderGroup.shared.addCommand(MBCommander.Repo.Search.self)
        MBCommanderGroup.shared.addCommand(MBCommander.GitSheet.self)
        MBCommanderGroup.shared.addCommand(MBCommander.GitSheet.Status.self)
        MBCommanderGroup.shared.addCommand(MBCommander.GitSheet.Fetch.self)
        MBCommanderGroup.shared.addCommand(MBCommander.GitSheet.Pull.self)
        MBCommanderGroup.shared.addCommand(MBCommander.GitSheet.Push.self)
    }

}
