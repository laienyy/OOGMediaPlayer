//
//  OOGAudioPlayerProvider+OOG200.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/11/4.
//

import Foundation

public extension OOGAudioPlayerProvider where Album == AudioAlbumModel {
    /// 根据项目、Type 获取专辑列表
    func getMusics(info: GetBGMListApiInfo, playAutomatically: Bool = true) async throws {
        
        do {
            let dtos: [AudioAlbumDTO] = try await ApiProvider.getBackgroundMedia(info)
            let models: [AudioAlbumModel] = dtos.map({ $0.asAlbumEntity().asAlbumModel() })
            albumList.append(contentsOf: models)
            updateSongsUseCacheState(isUseCache)
            reloadData(self.albumList, playAutomatically: playAutomatically)
            
        } catch let error {
            log(prefix: .mediaPlayer, "Get media list failed:", error)
            throw error
        }
    }
    
    
    func getMusics(_ scheme: ProjectScheme, _ project: OOGProject, types: [BgmPlayType], playAutomatically: Bool ) async throws {
        
        do {
            var models: [AudioAlbumModel] = []
            for type in types {
                let info = GetBGMListApiInfo(scheme: scheme, project: project, type: type)
                let dtos: [AudioAlbumDTO] = try await ApiProvider.getBackgroundMedia(info)
                // 转换数据类型
                let albumList = dtos.map({ $0.asAlbumEntity().asAlbumModel() })
                
                models.append(contentsOf: albumList)
            }
            
            albumList.append(contentsOf: models)
            updateSongsUseCacheState(isUseCache)
            reloadData(self.albumList, playAutomatically: playAutomatically)
            
        } catch let error {
            log(prefix: .mediaPlayer, "Get media list failed:", error)
            throw error
        }
    }
}
