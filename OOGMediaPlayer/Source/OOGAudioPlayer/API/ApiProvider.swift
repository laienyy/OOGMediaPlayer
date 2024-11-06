//
//  ApiProvider.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/18.
//

import Foundation


/**
 * `Entity` — 用于数据库交互
 *
 * `DTO` — 用户服务端与客户端进行交互
 *
 *  暂未实现数据库，暂时直接将`DTO`转为`Model`
 *
 */

public class ApiProvider {
    
    public static func getBackgroundMedia(_ project: OOGProject, _ type: BgmPlayType) async throws -> [AudioAlbumDTO] {
        let api = BackgroundMediaAPI.getBGM(project, type)
        let res: JsonArrayResponse<AudioAlbumDTO> = try await Request(api: api).resume()
        
        if let error = res.error() {
            throw error
        }
        let list = res.data
        return list ?? []
    }
}


extension ApiProvider {
//    let params = api.params.map({ "\($0.key)=\($0.value)"})
//    let urlString = api.urlString.appending("?" + params.joined(separator: ":"))
    
}
