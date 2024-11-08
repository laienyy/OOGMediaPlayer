//
//  PlayerSampleSettings.swift
//  MediaPlayerSample
//
//  Created by YiYuan on 2024/10/21.
//

import Foundation

//public struct CALayerCornerCurve : Hashable, Equatable, RawRepresentable, @unchecked Sendable {
//
//    public init(rawValue: String)
//}

public struct AudioPlayerSettingScheme: Hashable, Equatable, RawRepresentable, Codable {
    
    public var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}


public extension AudioPlayerSettingScheme {
    static let bgm = AudioPlayerSettingScheme(rawValue: "BackgroundMediaPlayer")
}


extension OOGAudioPlayerSettings {
    
    /// 持久化
    public func save() throws {
        let data = try JSONEncoder().encode(self)
        UserDefaults.standard.setValue(data, forKey: .settings, scheme: scheme)
    }
}

public class OOGAudioPlayerSettings: Codable {
    
    /// 可以根据不同业务，设置`scheme`进行区分
    public var scheme: AudioPlayerSettingScheme
    
    /// 收藏列表
    public var favoriteList = [Int]()
    
    
    /// 是否启用播放
    public var isEnablePlayer: Bool
    /// 是否启用缓存
    public var isEnableCache: Bool
    /// 播放器音量
    public var volumn: Float
    
    
    /// 当前播放音频ID
    public var currentAudioID: Int?
    
    /// 循环模式
    public var loopMode: MediaPlayerControl.LoopMode = .none
    /// 单曲循环ID，用于记录单曲循环指定的音乐ID
    public var loopDesignatedSongID: Int?
    /// 列表循环ID，记录专辑循环指定的专辑ID
    public var loopDesignateAlbumID: Int?
    
    
    public init(scheme: AudioPlayerSettingScheme, isEnablePlayer: Bool, isEnableCache: Bool, playerVolumn: Float, currentAudioID: Int? = nil) {
        self.scheme = scheme
        self.isEnablePlayer = isEnablePlayer
        self.isEnableCache = isEnableCache
        self.volumn = playerVolumn
        self.currentAudioID = currentAudioID
    }
}

extension OOGAudioPlayerSettings {
    
    /// 根据Scheme加载
    public static func loadScheme(_ scheme: AudioPlayerSettingScheme) -> OOGAudioPlayerSettings {
        guard let settingsData: Data = UserDefaults.standard.value(forKey: .settings, scheme: scheme),
              let settings = try? JSONDecoder().decode(OOGAudioPlayerSettings.self, from: settingsData) else {
            return .init(scheme: scheme, isEnablePlayer: true, isEnableCache: true, playerVolumn: 1.0)
        }
        
        return settings
    }
    
    public func isFavorite(_ song: BGMSong) -> Bool {
        favoriteList.contains(song.id)
    }
    
    public func setFavorite(for song: BGMSong, _ isFavorite: Bool) {
        if isFavorite {
            guard !favoriteList.contains(where: { $0 == song.id }) else {
                return // 已经添加
            }
            favoriteList.append(song.id)
            log(prefix: .mediaPlayer, "Add favorite song:", song)
        } else {
            favoriteList.removeAll(where: { $0 == song.id })
            log(prefix: .mediaPlayer, "Remove favorite song:", song)
        }
        do {
            try save()
        } catch let error {
            log(prefix: .mediaPlayer, "Failed to save favorite list, error: \(error)")
        }
    }
    
    public func selectFavoriteSongs<T: BGMSong>(by songs: [T]) -> [T] {
        return favoriteList.compactMap { id in
            let song = songs.first(where: { $0.id == id })
            return song
        }
    }
    
}

extension OOGAudioPlayerSettings {
    public func isLoop(_ song: BGMSong) -> Bool {
        return loopDesignatedSongID == song.id
    }
    
    public func setDesignatedSongLoop(_ song: BGMSong?) {
        loopDesignatedSongID = song?.id
    }
    
    public func removeDesignatedSongLoop() {
        loopDesignatedSongID = nil
    }
    
    public func isAlbumLoop(_ album: any BGMAlbum) -> Bool {
        return loopDesignateAlbumID == album.id
    }
    
    public func setDesignatedAlbumLoop(_ album: (any BGMAlbum)?) {
        loopDesignateAlbumID = album?.id
    }
}


enum OOGAudioPlayerUserDefaultsValueKey: String {
    
    case settings
    
    func keyValue(_ scheme: AudioPlayerSettingScheme) -> String {
        "com.4m.OOGAudioPlayerValueKey.\(scheme.rawValue).\(rawValue)"
    }
}

extension UserDefaults {
    
    func setValue(_ value: Any?, forKey key: OOGAudioPlayerUserDefaultsValueKey, scheme: AudioPlayerSettingScheme) {
        setValue(value, forKey: key.keyValue(scheme))
    }
    
    func value<T: Any>(forKey: OOGAudioPlayerUserDefaultsValueKey, scheme: AudioPlayerSettingScheme) -> T? {
        return value(forKey: forKey.keyValue(scheme)) as? T
    }
    
}
