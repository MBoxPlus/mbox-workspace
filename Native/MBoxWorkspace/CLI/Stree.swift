//
//  Stree.swift
//  MBoxWorkspace
//
//  Created by 詹迟晶 on 2019/9/30.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

open class SourceTreeApp: ExternalApp {
    public override init(name: String? = nil) {
        super.init(name: name ?? "SourceTree")
    }
}

extension MBCommander {
    open class Stree: Fork {

        open class override var description: String? {
            return "Quckly open git repository in the SourceTree app."
        }

        open override func getApp() -> ExternalApp {
            return SourceTreeApp()
        }
    }
}

