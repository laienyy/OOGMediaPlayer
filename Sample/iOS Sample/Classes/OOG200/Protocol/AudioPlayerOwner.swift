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
    var playerProvider: OOGAudioPlayerProvider<AudioAlbumModel> { get }
    var settings: OOGAudioPlayerSettings { get }
}

extension AudioAlbumModel {
    var isFavoriteAlbum: Bool {
        return id == favoriteAlbumID
    }
}

extension AudioPlayerOwner {
    
    func getFavoriteAlbum() -> AudioAlbumModel? {
        return playerProvider.albumList.first(where: { $0.isFavoriteAlbum })
    }
    
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
        
        settings.loopDesignatedSongID = song.resId
        settings.loopDesignateAlbumID = nil
        
        do {
            try settings.save()
            print("AudioPlayer - Set loop mode: \(playerProvider.loopMode.userInterfaceDisplay), song ID: \(song.resId)")
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
    
    func setAlbumShuffleLoop(album: any BGMAlbum) {
        playerProvider.loopMode = .albumShuffle
        settings.loopMode = .albumShuffle
        
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
        return settings.favoriteList.contains(song.resId)
    }
    
    func isLoop(song: BGMSong) -> Bool {
        return playerProvider.loopMode == .single && settings.loopDesignatedSongID == song.resId
    }
    
    func isLoop(album: any BGMAlbum) -> Bool {
        return playerProvider.loopMode == .album && settings.loopDesignateAlbumID == album.id
    }
    
    func isAlbumShuffle(_ album: any BGMAlbum) -> Bool {
        return playerProvider.loopMode == .albumShuffle && settings.loopDesignateAlbumID == album.id
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
    
    private func geneateDefaultFavoriteAlbum() -> AudioAlbumModel {
        let album = AudioAlbumModel()
        album.playlistName = "我最喜欢的"
        album.id = favoriteAlbumID
        return album
    }
    
    // 根据当前播放列表与喜欢的音频ID，刷新喜爱专辑
    func reloadFavoriteAlbum() {
        // 获得实例
        let album = playerProvider.albumList.first(where: { $0.isFavoriteAlbum }) ?? geneateDefaultFavoriteAlbum()
        // 将非《喜欢》专辑的歌曲集合
        let songs = playerProvider.albumList.filter({ !$0.isFavoriteAlbum }).flatMap({ $0.mediaList })
        
        // 筛选处喜欢的歌曲
        let favSongs: [AudioModel] = settings.selectFavoriteSongs(by: songs)

        guard favSongs.count > 0 else {
            return
        }
        // 更新列表
        album.mediaList = favSongs
        
        if let index = playerProvider.albumList.firstIndex(where: { $0.isFavoriteAlbum }) {
            playerProvider.reload(section: index, album)
        } else {
            var list = playerProvider.albumList
            list.insert(album, at: 0)
            playerProvider.reloadData(list)
        }
    }

}

extension AudioPlayerOwner {
    
    func updatePlayerWithSettings() {
        playerProvider.syncSettings(settings)
    }
    
    func resumePlayAudioBySettings() async throws {
        try await playerProvider.resumePlay(by: settings, playAutomatically: false)
    }
    
    func playAudioIfDataSourceExists() {
        if playerProvider.isExistsValidMedia() {
            Task {
                switch playerProvider.playerStatus {
                case .finished, .error, .stoped:
                    if let previousAudioID = settings.currentAudioID, let indexPath = playerProvider.indexPathOf(mediaID: previousAudioID) {
                        // 播放之前
                        try await playerProvider.load(indexPath: indexPath, autoPlay: true)
                    } else {
                        try await playerProvider.playNext()
                    }
                    
                case .paused:
                    await playerProvider.play()
                    
                case .prepareToPlay, .playing:
                    break
                    
                @unknown default:
                    break
                }
            }
        }
    }
}
