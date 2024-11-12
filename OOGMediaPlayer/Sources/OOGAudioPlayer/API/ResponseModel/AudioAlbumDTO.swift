//
//  AudioAlbum.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/21.
//

import Foundation

// 接口代码模型，仅供接口解析使用

public struct AudioAlbumDTO: Codable {
    
    var id: Int = 0
    
    /// 列表名称
    var playlistName: String?
    /// iPhone 封面图
    var phoneCoverImgUrl: String?
    /// iPhone 详情图
    var phoneDetailImgUrl: String?

    /// 是否收费
    var subscription: Int? = 0
    /// iPad封面图
    var tabletCoverImgUrl: String?
    /// iPad详情图
    var tabletDetailImgUrl: String?
    /// 音频信息列表
    var musicList: [Song]?

}

extension AudioAlbumDTO {
    
    struct Song: Codable {
        var id: Int = 0
        /// 数据ID
        var resId: Int = 0
        /// 音频文件url
        var audio: String?
        /// 音频时长
        var audioDuration: Int?
        /// 音频文件名称
        var audioName: String?
        /// 封面图
        var coverImgUrl: String?
        /// 详情图
        var detailImgUrl: String?
        /// 显示名称
        var displayName: String?
        /// 音频名称
        var musicName: String?
        /// 音频类型（关联字典表）
        var musicType: String?
        /// App短链接
        var shortLink: String?
        // 0不收费 1收费
        var subscription: Int? = 0
    }
}


extension AudioAlbumDTO {
    
    func asAlbumEntity() -> BackgroundMediaAlbumEntity {
        var model = BackgroundMediaAlbumEntity()
        model.id = id
        model.playlistName = playlistName
        model.phoneCoverImgUrl = phoneCoverImgUrl
        model.phoneDetailImgUrl = phoneDetailImgUrl
        model.subscription = subscription == 1
        model.tabletCoverImgUrl = tabletCoverImgUrl
        model.tabletDetailImgUrl = tabletDetailImgUrl
        
        model.musicList = musicList?.map({ song in
            var model = BackgroundMediaEntity()
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
            model.subscription = song.subscription == 1
            return model
        }) ?? .init()
        
        return model
        
    }
}
