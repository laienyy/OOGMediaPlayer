//
//  OOG106+FilePath.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/12/2.
//

import UIKit


// 给116使用

public extension FileItem {
    
    /**
     *  根据BGM网络连接生成文件信息
     *
     * @parameter: `urlString` - 网络链接地址
     */
    static func bgm(playListId: Int) -> FileItem {
        return FileItem(root: .cache, directory: .backgroundMedia, fileName: "playListId_\(playListId).json")
    }
}

public extension FileItem {
    
    static func bgmAlbumListJson(playListId: Int) -> FileItem {
        return FileItem(root: .cache, directory: .backgroundMediaAlbumListJson, fileName: "playListId_\(playListId).json")
    }
}
