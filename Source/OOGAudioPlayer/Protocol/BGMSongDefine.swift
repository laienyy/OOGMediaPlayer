//
//  BGMSongDefine.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/22.
//

import Foundation

//extension BGMSong where Self: Equatable {
//    static func == (lhs: Self, rhs: Self) -> Bool {
//        return lhs.id == rhs.id
//    }
//}

public protocol BGMSong: LocalMediaPlayable {
    
    var `id`: Int { get }
    /// 数据ID
    var resId: Int { get }
    /// 音频文件url
    var audio: String? { get }
    /// 音频时长
    var audioDuration: Int? { get }
    /// 音频文件名称
    var audioName: String? { get }
    /// 封面图
    var coverImgUrl: String? { get }
    /// 详情图
    var detailImgUrl: String? { get }
    /// 显示名称
    var displayName: String? { get }
    /// 音频名称
    var musicName: String? { get }
    /// 音频类型（关联字典表）
    var musicType: String? { get }
    /// App短链接
    var shortLink: String? { get }
    /// 0不收费 1收费
    var subscription: Bool  { get }
    /// 是否使用缓存
    var useCache: Bool { get set }
}

