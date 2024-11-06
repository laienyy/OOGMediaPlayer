//
//  BackgroundMediaAPI.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/18.
//

import Foundation

enum ApiMethod: String {
    case GET
}

enum BackgroundMediaAPI {
    /// 背景音乐
    case getBGM(OOGProject, _ type: BgmPlayType)
}

extension BackgroundMediaAPI: API {
    
    var urlString: String {
        switch self {
        case .getBGM(_, _):
            return domain.appending(path)
        }
    }
    
    var domain: String {
        switch self {
        case let .getBGM(domain, _):
            return domain.domain()
        }
    }
    
    var path: String {
        switch self {
        case let  .getBGM(domain, bgmType):
            return domain.pathFor(bgm: bgmType)
        }
    }
    
    func asURL() -> URL {
        return URL(string: domain + path)!
    }
    
    var method: ApiMethod {
        return .GET
    }
    
    var parameters: [String: AnyHashable]? {
        switch self {
        case let .getBGM(domain, type):
            switch domain {
            case .oog200:
                return type.asParameter()
            }
        }
    }
    
}

