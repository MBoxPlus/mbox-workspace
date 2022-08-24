//
//  Status+Sync.swift
//  MBoxWorkspace
//
//  Created by Whirlwind on 2021/2/28.
//  Copyright © 2021 bytedance. All rights reserved.
//

import Foundation
import MBoxCore
import MBoxGit

extension MBCommander.Status {
    public func syncStatus() throws {
//        let fm = FileManager.default
//        for cachedRepo in MBConfig.Repo.all(self.workspace) {
//            guard let repo = self.config.currentFeature.findRepo(cachedRepo) else {
//                if !cachedRepo.isCache {
//                    try UI.section("[\(cachedRepo)]".ANSI(.yellow)) {
//                        if !cachedRepo.isWorking {
//                            try UI.log(verbose: "The path `\(cachedRepo.path!)` is invalid, remove it.") {
//                                try fm.removeItem(atPath: cachedRepo.path!)
//                            }
//                        } else {
//                            try UI.log(verbose: "Make repo cache") {
//                                try cachedRepo.cache()
//                            }
//                        }
//                    }
//                }
//                continue
//            }
//            try UI.section("[\(repo)]".ANSI(.yellow)) {
//                if !repo.isWorking {
//                    try UI.log(verbose: "Make repo work") {
//                        try repo.work()
//                    }
//                }
//                if repo.url != repo.git?.url {
//                    try UI.log(verbose: "Update url `\(repo.url ?? "null")` -> `\(repo.git?.url ?? "null")`") {
//                        let oldWorkPath = repo.workingPath
//                        let oldCachePath = repo.cachePath
//                        let oldPath = oldWorkPath.isSymlink ? oldCachePath : oldWorkPath
//
//                        repo.fullName = "" // 重置文件名
//                        repo.url = repo.git?.url
//
//                        let tmpPath = oldPath+".tmp"
//                        try UI.log(verbose: "Move `\(oldPath.relativePath(from: self.workspace.rootPath))` -> `\(tmpPath.relativePath(from: self.workspace.rootPath))`") {
//                            try fm.moveItem(atPath: oldPath, toPath: tmpPath)
//                        }
//
//                        if oldWorkPath.isExists || oldWorkPath.isSymlink {
//                            try UI.log(verbose: "Remove `\(oldWorkPath.relativePath(from: self.workspace.rootPath))`") {
//                                try fm.removeItem(atPath: oldWorkPath)
//                            }
//                        }
//                        if oldCachePath.isExists || oldCachePath.isSymlink {
//                            try UI.log(verbose: "Remove `\(oldCachePath.relativePath(from: self.workspace.rootPath))`") {
//                                try fm.removeItem(atPath: oldCachePath)
//                            }
//                        }
//                        try UI.log(verbose: "Move `\(tmpPath.relativePath(from: self.workspace.rootPath))` -> `\(repo.workingPath.relativePath(from: self.workspace.rootPath))`") {
//                            try fm.moveItem(atPath: tmpPath, toPath: repo.workingPath)
//                        }
//                        try UI.log(verbose: "Link `\(repo.cachePath.relativePath(from: self.workspace.rootPath))` -> `\(repo.workingPath.relativePath(from: self.workspace.rootPath))`") {
//                            try fm.createSymbolicLink(atPath: repo.cachePath, withDestinationPath: repo.workingPath)
//                        }
//                    }
//                }
//            }
//        }
        self.config.save()
    }

}

