//
//  OOGProject.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/22.
//

import Foundation

public enum OOGProject {
    case oog200
    
    // xx项目域名
    func domain() -> String {
        switch self {
        case .oog200:
            return oog200Domain()
        }
    }
    
    // xx项目背景音乐接口路径
    func pathFor(bgm: BgmPlayType) -> String {
        switch self {
        case .oog200:
            return "v1/playlist/listByType"
        }
    }
}
