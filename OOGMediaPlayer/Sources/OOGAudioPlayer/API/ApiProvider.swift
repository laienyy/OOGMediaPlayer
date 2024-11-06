//
//  ApiProvider.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/18.
//

import Foundation


public class ApiProvider {
    
    public static func getBackgroundMedia(_ param: GetBGMListApiInfo) async throws -> [AudioAlbumDTO] {
        let res: JsonArrayResponse<AudioAlbumDTO> = try await Request(api: param).resume()
        
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
