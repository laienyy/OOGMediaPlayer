//
//  OOGAudioPlayerProvider+OOGAudioPlayerSettings.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/11/4.
//

import UIKit


//MARK: - OOGAudioPlayerProvider & OOGAudioPlayerSettings
public extension OOGAudioPlayerProvider {
    
    // 根据设置同步播放器的设置
    func syncSettings(_ settings: OOGAudioPlayerSettings) {
        
        isUseCache = settings.isEnableCache
        volumn = settings.volumn
        loopMode = settings.loopMode
    }
    
    // 根据设置播放歌曲
    func resumePlayAudioBySetting(_ settings: OOGAudioPlayerSettings) {
        // 恢复单曲循环播放
        if settings.loopMode == .single,
           let id = settings.loopDesignatedSongID,
           let indexPath = indexPathOf(mediaID: id) {
            
            // 播放指定的单曲循环曲目
            play(indexPath: indexPath)
        }
        // 恢复专辑循环播放
        else if settings.loopMode == .album,
                let id = settings.loopDesignateAlbumID,
                let index = albumList.firstIndex(where: { $0.id == id && $0.mediaList.count > 0 }) {
            
            if let songId = settings.currentAudioID,
               let indexPath = indexPathOf(mediaID: songId),
               index == indexPath.section {
                // 如果此前最后播放的曲目在指定专辑，播放上次之前播放的曲目
                play(indexPath: indexPath)
            } else {
                // 播放指定专辑首曲
                let indexPath = IndexPath(row: 0, section: index)
                play(indexPath: indexPath)
            }
        }
        // 恢复常规播放
        else if let id = settings.currentAudioID,
           currentSong()?.id != id,
           let indexPath = indexPathOf(mediaID: id) {
            play(indexPath: indexPath)
        }
    }
    
    @discardableResult
    func playIfExists(id: Int) -> Bool {
        guard let indexPath = indexPathOf(mediaID: id) else {
            return false
        }
        play(indexPath: indexPath)
        return true
    }
    
    // 检查是否根据循环模式是否需要切换指定的循环区间的歌曲
    func playDesignatedLoopSongIfNeeds(settings: OOGAudioPlayerSettings) {
        
        if loopMode == .single,
           let songId = settings.loopDesignatedSongID,
           currentSong()?.id != songId {
            
            playIfExists(id: songId)
        }
        else if
            loopMode == .album,
            let albumId = settings.loopDesignateAlbumID,
            currentAlbum()?.id != albumId {
            
            guard let albumIndex = albumList.firstIndex(where: { $0.id == albumId }) else {
                return
            }
            guard !albumList[albumIndex].mediaList.isEmpty else {
                return
            }
            let indexPath = IndexPath(row: 0, section: albumIndex)
            play(indexPath: indexPath)
        }
        

    }
}
