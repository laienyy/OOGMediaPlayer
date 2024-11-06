//
//  AudioAlbumModel.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/21.
//

import UIKit

// MARK: - 专辑

public class AudioAlbumModel: NSObject, BGMAlbum {
    
    public var name: String? { playlistName }
    
    public var id: Int = 0
    
    /// 是否收费
    public var subscription : Bool = false
    /// 列表名称
    public var playlistName: String?
    
    public var localCoverImage: UIImage?
    
    /// iPhone 封面图
    public var phoneCoverImgUrl: String?
    /// iPhone 详情图
    public var phoneDetailImgUrl: String?

    /// iPad封面图
    public var tabletCoverImgUrl: String?
    /// iPad详情图
    public var tabletDetailImgUrl: String?
    /// 音频信息列表
    public var mediaList: [AudioModel] = []
    
    public override init() {}
    
    public override var description: String {
        return "ID: \(id), name: \(playlistName ?? ""), medias: [\n\t\(mediaList.map({ $0.description }).joined(separator: "\n\t"))\n]"
    }
}

