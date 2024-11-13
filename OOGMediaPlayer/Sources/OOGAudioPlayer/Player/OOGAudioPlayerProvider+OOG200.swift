//
//  OOGAudioPlayerProvider+OOG200.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/11/4.
//

import Foundation

public extension OOGAudioPlayerProvider where Album == AudioAlbumModel {
    
    func getMusicFromServer(_ info: GetBGMListApiInfo, updateToCache: Bool = true)
    async throws -> [AudioAlbumModel] {
        let info = GetBGMListApiInfo(scheme: info.scheme,
                                     project: info.project,
                                     type: info.type,
                                     language: "en")
        let models = try await [AudioAlbumModel].getListFromAPI(info)
        models.storeListToCache(info.type)
        updateSongsUseCacheState(isUseCache)
        return models
    }
    
    
    func loadOrReloadDataFromServer(_ info: GetBGMListApiInfo) async throws {
        let models = try await getMusicFromServer(info, updateToCache: true)
        self.albumList = models
        reloadData(self.albumList, playAutomatically: playAutomatically)
    }

}

