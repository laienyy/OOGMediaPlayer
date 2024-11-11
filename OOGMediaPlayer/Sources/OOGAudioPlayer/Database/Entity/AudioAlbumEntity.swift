//
//  AudioAlbumEntity.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/21.
//

import Foundation

@DebugDescription
struct BackgroundMediaAlbumEntity: Codable {

    public var id: Int = 0
    /// 喜欢的
    public var isFav: Bool = false
    
    /// 是否收费
    public var subscription : Bool = false
    
    /// 列表名称
    public var playlistName: String?
    /// iPhone 封面图
    public var phoneCoverImgUrl: String?
    /// iPhone 详情图
    public var phoneDetailImgUrl: String?

    /// iPad封面图
    public var tabletCoverImgUrl: String?
    /// iPad详情图
    public var tabletDetailImgUrl: String?
    /// 音频信息列表
    public var musicList: [BackgroundMediaEntity] = .init()
    
}

struct BackgroundMediaEntity: Codable {
    public var id: Int = 0
    /// 数据ID
    public var resId: Int = 0
    /// 音频文件url
    public var audio: String?
    /// 音频时长
    public var audioDuration: Int?
    /// 音频文件名称
    public var audioName: String?
    /// 封面图
    public var coverImgUrl: String?
    /// 详情图
    public var detailImgUrl: String?
    /// 显示名称
    public var displayName: String?
    /// 音频名称
    public var musicName: String?
    /// 音频类型（关联字典表）
    public var musicType: String?
    /// App短链接
    public var shortLink: String?
    // 0不收费 1收费
    public var subscription: Bool = false
}

extension BackgroundMediaAlbumEntity {
    
    func asAlbumModel() -> AudioAlbumModel {
        let model = AudioAlbumModel()
        model.id = id
        model.playlistName = playlistName
        model.phoneCoverImgUrl = phoneCoverImgUrl
        model.phoneDetailImgUrl = phoneDetailImgUrl
        model.subscription = subscription
        model.tabletCoverImgUrl = tabletCoverImgUrl
        model.tabletDetailImgUrl = tabletDetailImgUrl
        
        model.mediaList = musicList.map({ song in
            let model = AudioModel()
            model.resId = song.resId
            model.audio = song.audio
            model.audioDuration = song.audioDuration
            model.audioName = song.audioName
            model.coverImgUrl = song.coverImgUrl
            model.detailImgUrl = song.detailImgUrl
            model.displayName = song.displayName
            model.musicName = song.musicName
            model.musicType = song.musicType
            model.shortLink = song.shortLink
            model.subscription = song.subscription
            return model
        })
        
        return model
    }
    
}
