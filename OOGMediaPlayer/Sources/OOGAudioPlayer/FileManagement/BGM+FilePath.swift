//
//  FileItem+BGM.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/17.
//

import Foundation

public extension FileDirectory {
    /// 背景音乐文件夹
    static let backgroundMedia = FileDirectory(string: "/media/com.7m.BackgroundMedia")
    /// 背景音乐专辑列表 JSON 文件
    static let backgroundMediaAlbumListJson = FileDirectory(string: "/media/com.7m.BackgroundMediaAlbumListJson")
}

public extension FileItem {
    
    /**
     *  根据BGM网络连接生成文件信息
     *
     * @parameter: `urlString` - 网络链接地址
     */
    static func bgm(_ fileName: String) -> FileItem {
        return FileItem(root: .cache, directory: .backgroundMedia, fileName: fileName)
    }
    
}

extension BgmPlayType {
    var cacheFileName: String {
        switch self {
        case .planClassicAndChair:
            return "planClassicAndChair.json"
        case .animation:
            return "animation.json"
        case .poseLibrary:
            return "poseLibrary.json"
        }
    }
}

public extension FileItem {
    
    static func bgmAlbumListJson(_ type: BgmPlayType) -> FileItem {
        return FileItem(root: .cache, directory: .backgroundMediaAlbumListJson, fileName: type.cacheFileName)
    }
}
