//
//  GetMediaListAPI.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/11/6.
//

import Foundation

public struct GetBGMListApiInfo: API {
    public let scheme: ProjectScheme
    public let project: OOGProject
    public let type: BgmPlayType
    
    public init(scheme: ProjectScheme, project: OOGProject, type: BgmPlayType) {
        self.scheme = scheme
        self.project = project
        self.type = type
    }
    
    var method: ApiMethod = .GET
    var parameters: [String: AnyHashable]? {
        return type.asParameter()
    }
    
    func asURL() -> URL {
        return URL(string: domain + path)!
    }
    
    var domain: String {
        return project.domain(scheme: scheme)
    }
    var path: String {
        switch project {
        case .oog200: return "v1/playlist/listByType"
        }
    }
}
