//
//  BGMPlayerProvider.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/21.
//

import Foundation

public class OOGAudioPlayerProvider<Album: BGMAlbum>: LocalAudioPlayerProvider {
    
    public var albumList: [Album] {
        get { (self.getItems() as? [Album]) ?? [] }
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
    public func currentSong() -> Album.BGMAudioType? {
        return currentItem() as? Album.BGMAudioType
    }
    
    /// 根据`section`获取专辑
    public func getAlbum(at section: Int) -> (Album)? {
        guard section < albumList.count else {
            return nil
        }
        return albumList[section]
    }
    
    /// 根据`indexPath`获取音乐
    public func getSong(at indexPath: IndexPath) -> Album.BGMAudioType? {
        
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
            for media in album.mediaList {
                media.useCache = isUseCache
            }
        }
    }
    
}

