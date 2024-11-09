//
//  OOGAudioPlayerProvider+OOG200.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/11/4.
//

import Foundation

public extension OOGAudioPlayerProvider where Album == AudioAlbumModel {
    /// 根据项目、Type 获取专辑列表
    func addMusicsFromServer(info: GetBGMListApiInfo, playAutomatically: Bool = true) async throws {
        
        do {
            let models: [AudioAlbumModel] = try await .getListFromAPI(info)
            models.storeListToCache(info.type)
            
            albumList.append(contentsOf: models)
            updateSongsUseCacheState(isUseCache)
            reloadData(self.albumList, playAutomatically: playAutomatically)
            
        } catch let error {
            log(prefix: .mediaPlayer, "Get media list failed:", error)
            throw error
        }
    }
    
    
    func addMusicsFromServer(_ scheme: ProjectScheme, _ project: OOGProject, types: [BgmPlayType], playAutomatically: Bool ) async throws {
        
        for type in types {
            let info = GetBGMListApiInfo(scheme: scheme, project: project, type: type, language: "en")
            try await addMusicsFromServer(info: info, playAutomatically: false)
        }
        
        if playAutomatically, currentIndexPath == nil {
            playNext()
        }
    }
}

