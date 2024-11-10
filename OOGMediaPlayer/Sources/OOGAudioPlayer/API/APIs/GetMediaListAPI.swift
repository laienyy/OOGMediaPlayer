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
    public let language: String
    
    public init(scheme: ProjectScheme, project: OOGProject, type: BgmPlayType, language: String = "en") {
        self.scheme = scheme
        self.project = project
        self.type = type
        self.language = language
    }
    
    var method: ApiMethod = .GET
    var parameters: [String: AnyHashable]? {
        var dic = type.asParameter()
        dic["lang"] = language
        return dic
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
