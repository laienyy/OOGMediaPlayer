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
        volume = settings.volumn
        loopMode = settings.loopMode
        isEnable = settings.isEnablePlayer

        if let id = settings.currentAudioID, let indexPath = indexPathOf(mediaID: id) {
            currentIndexPath = indexPath
        }
    }
    
    /**
     
     根据设置播放歌曲, 返回否则为未根据设置找到合适的曲目
     
     优先级如下：
     1. 根据单曲循环模式找到曲目位置，并播放 （如果歌曲无效，取消播放）
     2. 根据专辑循环模式找到专辑的播放位置
        a. 当`currentIndex` 在目标专辑内，则播放`currentIndex`
        b. 当`currentIndex` 不在目标专辑内，播放专辑的第一首有效（若整个专辑都为无效，则不播放任何歌曲）
     3. 根据`currentIndex`恢复播放 （如果歌曲无效，取消播放）
     
     */
    @discardableResult
    func resumePlay(by settings: OOGAudioPlayerSettings, playAutomatically: Bool) -> Bool {
        
        var specificIndexPath: IndexPath?
        
        // 恢复单曲循环播放
        if settings.loopMode == .single,
           let id = settings.loopDesignatedSongID,
           let indexPath = indexPathOf(mediaID: id) {
            
            guard media(at: indexPath)?.isValid ?? false else {
                // 歌曲无效，直接取消恢复播放
                return false
            }
            specificIndexPath = indexPath
        }
        // 恢复专辑循环播放
        else if settings.loopMode == .album,
                let id = settings.loopDesignateAlbumID,
                let index = albumList.firstIndex(where: { $0.id == id && $0.mediaList.count > 0 }) {
            
            if let songId = settings.currentAudioID,
               let indexPath = indexPathOf(mediaID: songId),
               index == indexPath.section {
                // 如果此前最后播放的曲目在指定专辑，播放上次之前播放的曲目
                specificIndexPath = indexPath
            }
            // 查询专辑第一个有效的多歌曲
            else if let validElement = album(at: index)?.mediaList.enumerated().first(where: { $0.element.isValid }) {
                // 播放指定专辑首曲
                let indexPath = IndexPath(row: validElement.offset, section: index)
                specificIndexPath = indexPath
            }
        }
        // 恢复上次播放的歌曲 (如果无效则不播放)
        else if let id = settings.currentAudioID,
                let indexPath = indexPathOf(mediaID: id),
                media(at: indexPath)?.isValid == true {
            
            specificIndexPath = indexPath
        }
        
        if let indexPath = specificIndexPath {
            Task {
                try await toPlay(indexPath: indexPath, playAutomaticly: playAutomatically)
            }
        }
        
        return specificIndexPath != nil
    }
    
    @discardableResult
    func playIfExists(id: Int) -> Bool {
        guard let indexPath = indexPathOf(mediaID: id) else {
            return false
        }
        load(indexPath: indexPath, autoPlay: true)
        return true
    }
    
    // 检查是否根据循环模式是否需要切换指定的循环区间的歌曲
    func playDesignatedLoopSongIfNeeds(settings: OOGAudioPlayerSettings) {
        
        if loopMode == .single,
           let songId = settings.loopDesignatedSongID,
           currentSong()?.resId != songId {
            
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
            load(indexPath: indexPath, autoPlay: true)
        }
        
    }
}
