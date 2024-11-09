//
//  AudioPlayerOwner.swift
//  iOS Sample
//
//  Created by YiYuan on 2024/11/5.
//

import Foundation
import UIKit
import OOGMediaPlayer

private let favoriteAlbumID = -1

protocol AudioPlayerOwner {
    associatedtype T: BGMAlbum
    
    var playerProvider: OOGAudioPlayerProvider<T> { get }
    var settings: OOGAudioPlayerSettings { get }
}

extension AudioPlayerOwner {
    
    // 设置循环播放 (非单曲、专辑循环使用)
    func setPlayerLoop(mode: MediaPlayerControl.LoopMode) {
        playerProvider.loopMode = mode
        settings.loopMode = mode
        
        settings.loopDesignateAlbumID = nil
        settings.loopDesignatedSongID = nil
        
        do {
            try settings.save()
            print("AudioPlayer - Set loop mode: \(mode.userInterfaceDisplay)")
        } catch {
            print("Save settings error:", error)
        }
    }
    
    // 设置循环播放 - 单曲
    func setPlayerSingleLoop(song: BGMSong) {
        playerProvider.loopMode = .single
        settings.loopMode = .single
        
        settings.loopDesignatedSongID = song.id
        settings.loopDesignateAlbumID = nil
        
        do {
            try settings.save()
            print("AudioPlayer - Set loop mode: \(playerProvider.loopMode.userInterfaceDisplay), song ID: \(song.id)")
        } catch {
            print("Save settings error:", error)
        }
    }
    
    // 设置循环播放 - 专辑
    func setPlayerAlbumLoop(album: any BGMAlbum) {
        playerProvider.loopMode = .album
        settings.loopMode = .album
        
        settings.loopDesignateAlbumID = album.id
        settings.loopDesignatedSongID = nil
        
        do {
            try settings.save()
            print("AudioPlayer - Set loop mode: \(playerProvider.loopMode.userInterfaceDisplay), album ID: \(album.id)")
        } catch {
            print("Save settings error:", error)
        }
    }
    
    
    func isFavorite(song: BGMSong) -> Bool {
        return settings.favoriteList.contains(song.id)
    }
    
    func isLoop(song: BGMSong) -> Bool {
        return playerProvider.loopMode == .single && settings.loopDesignatedSongID == song.id
    }
    
    func isLoop(album: any BGMAlbum) -> Bool {
        return playerProvider.loopMode == .album && settings.loopDesignateAlbumID == album.id
    }

    func nextPlayableIndexPath(from: IndexPath) -> IndexPath? {
        
        for section in playerProvider.albumList.enumerated() {
            
            if section.offset < from.section {
                continue
            }
            
            for row in section.element.mediaList.enumerated() {
                if row.offset < from.row {
                    continue
                }
                if !row.element.subscription {
                    return IndexPath(row: row.offset, section: section.offset)
                }
            }
        }
        
        return nil
    }

}
