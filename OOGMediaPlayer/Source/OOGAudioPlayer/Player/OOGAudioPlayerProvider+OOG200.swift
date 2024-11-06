//
//  OOGAudioPlayerProvider+OOG200.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/11/4.
//

import Foundation

public extension OOGAudioPlayerProvider where Album == AudioAlbumModel {
    /// 根据项目、Type 获取专辑列表
    func getMusics(_ project: OOGProject, _ types: [BgmPlayType], playAutomatically: Bool = true) async throws {
        
        do {
            for type in types {
                let dtos: [AudioAlbumDTO] = try await ApiProvider.getBackgroundMedia(project, type)
                let models: [AudioAlbumModel] = dtos.map({ $0.asAlbumEntity().asAlbumModel() })
                albumList.append(contentsOf: models)
            }
            updateSongsUseCacheState(isUseCache)
            reloadData(self.albumList, playAutomatically: playAutomatically)
            
        } catch let error {
            log(prefix: .mediaPlayer, "Get media list failed:", error)
            throw error
        }
    }
}
