//
//  OOGProject.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/22.
//

import Foundation

public enum OOGProject {
    case oog200
}

public enum ProjectScheme {
    case distribution
    case preDistribution
    case test
    case dev
}

enum ApiMethod: String {
    case GET
}

public extension OOGProject {
    // xx项目域名
    func domain(scheme: ProjectScheme) -> String {
        switch self {
        case .oog200:
            switch scheme {
            case .distribution:     return "https://mango.7mfitness.com/cmsApp/oog200/"
            case .preDistribution:  return "https://mango-pre.7mfitness.com/cmsApp/oog200/"
            case .test:             return "https://backend-test.7mfitness.com/cmsApp/oog200/"
            case .dev:              return "https://backend-dev.7mfitness.com/cmsApp/oog200/"
            }
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

public enum BgmPlayType {
    
    case planClassicAndChair
    case poseLibrary
    case animation

    func asParameter() -> [String : AnyHashable] {
        switch self {
        case .planClassicAndChair:
            return ["playType" : "Plan_Classic and Chair"]
        case .poseLibrary:
            return ["playType" : "Pose Library"]
        case .animation:
            return ["playType" : "Animation"]
        }
    }
    
    var description: String {
        switch self {
        case .planClassicAndChair:
            return "Plan_Classic and Chair"
        case .poseLibrary:
            return "Pose Library"
        case .animation:
            return "Animation"
        }
    }
}
