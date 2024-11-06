//
//  BGMAlbumDefine.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/22.
//

import UIKit

public extension BGMAlbum {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}

public protocol BGMAlbum: MediaAlbum  {
    
    var id: Int { get }
    
    /// 是否收费
    var subscription : Bool { get }
    
    /// 列表名称
    var name: String? { get }
    
    /// iPhone 封面图
    var phoneCoverImgUrl: String? { get }
    /// iPhone 详情图
    var phoneDetailImgUrl: String? { get }
    
    /// iPad封面图
    var tabletCoverImgUrl: String? { get }
    /// iPad详情图
    var tabletDetailImgUrl: String? { get }
    associatedtype BGMAudioType: BGMSong
    /// 音频信息列表
    var mediaList: [BGMAudioType] { get }
    
}

