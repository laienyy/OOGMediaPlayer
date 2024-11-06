//
//  BGMPlayerProvider.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/21.
//

import Foundation

public class OOGAudioPlayerProvider<Album: BGMAlbum>: LocalAudioPlayerProvider {
    
    /// 专辑列表
    public var albumList: [Album] = [] {
        didSet {
            reloadItems(albumList)
        }
    }
    /// 是否使用缓存
    public var isUseCache: Bool = true {
        didSet { updateSongsUseCacheState(isUseCache) }
    }
    
    /// 当前专辑
    public func currentAlbum() -> Album? {
        guard let section = currentIndexPath?.section, section < albumList.count else {
            return nil
        }
        
        return albumList[section]
    }
    
    /// 当前播放的音乐
    public func currentSong() -> BGMSong? {
        return currentItem() as? BGMSong
    }
    
    /// 根据`section`获取专辑
    public func getAlbum(at section: Int) -> (Album)? {
        guard section < albumList.count else {
            return nil
        }
        return albumList[section]
    }
    
    /// 根据`indexPath`获取音乐
    public func getSong(at indexPath: IndexPath) -> BGMSong? {
        
        guard indexPath.section < albumList.count else {
            return nil
        }
        guard indexPath.row < albumList[indexPath.section].mediaList.count else {
            return nil
        }
        return albumList[indexPath.section].mediaList[indexPath.row]
    }
    
    func updateSongsUseCacheState(_ isUseCache: Bool) {
        for album in albumList {
            for var media in album.mediaList {
                media.useCache = isUseCache
            }
        }
    }
    
}

