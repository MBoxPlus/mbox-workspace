//
//  Tower.swift
//  MBoxWorkspace
//
//  Created by 詹迟晶 on 2019/9/30.
//  Copyright © 2019 bytedance. All rights reserved.
//

import Foundation
import MBoxCore

open class TowerApp: ExternalApp {
    public override init(name: String? = nil) {
        super.init(name: name ?? "Tower")
    }
}

extension MBCommander {
    open class Tower: Fork {

        open class override var description: String? {
            return "Quckly open git repository in the Tower app."
        }

        open override func getApp() -> ExternalApp {
            return TowerApp()
        }
    }
}
