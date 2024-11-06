//
//  BgmPlanType.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/18.
//

import Foundation

public enum BgmPlayType {
    
    case planClassicAndChair
    case poseLibrary
    case animation
    case all
    
    func asParameter() -> [String : AnyHashable] {
        switch self {
        case .planClassicAndChair:
            return ["playType" : "Plan_Classic and Chair"]
        case .poseLibrary:
            return ["playType" : "Pose Library"]
        case .animation:
            return ["playType" : "Animation"]
        case .all:
            let parameters = [String : AnyHashable]()
            return [BgmPlayType.planClassicAndChair, .poseLibrary, .animation].reduce(into: parameters) {
                let param = $1.asParameter()
                $0.merge(param, uniquingKeysWith: { (first, _) in first })
            }
        }
    }
}
