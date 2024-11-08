//
//  AudioAlbumModel.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/21.
//

import UIKit

// MARK: - 专辑

public class AudioAlbumModel: NSObject, BGMAlbum, Codable {
    
    enum CodingKeys: CodingKey {
        case id
        case subscription
        case playlistName
        case phoneCoverImgUrl
        case phoneDetailImgUrl
        case tabletCoverImgUrl
        case tabletDetailImgUrl
        case mediaList
    }
    
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


public extension [AudioAlbumModel] {
    
    @discardableResult
    func storeListToCache(_ type: BgmPlayType) -> Bool {
        do {
            let fileItem = FileItem.bgmAlbumListJson(type)
            try fileItem.write(data: try JSONEncoder().encode(self))
            return true
        } catch let error {
            log(prefix: .mediaPlayer, "Save AudioAlbumModel list of type (\(type.description) failed:", error)
            return false
        }
    }
    
    static func getListFromCache(_ type: BgmPlayType) -> [AudioAlbumModel]? {
        do {
            let fileItem = FileItem.bgmAlbumListJson(type)
            guard let data = fileItem.getDataFromDisk() else {
                return nil
            }
            return try JSONDecoder().decode(Self.self, from: data)
            
        } catch let error {
            log(prefix: .mediaPlayer, "Get AudioAlbumModel list of type (\(type.description) from disk cache failed:", error)
            return nil
        }
    }
    
    static func getListFromAPI(_ destination: GetBGMListApiInfo) async throws -> [AudioAlbumModel] {
        let info = GetBGMListApiInfo(scheme: destination.scheme, project: destination.project, type: destination.type)
        let dtos: [AudioAlbumDTO] = try await ApiProvider.getBackgroundMedia(info)
        // 转换数据类型
        let albumList = dtos.map({ $0.asAlbumEntity().asAlbumModel() })
        return albumList
    }
}
