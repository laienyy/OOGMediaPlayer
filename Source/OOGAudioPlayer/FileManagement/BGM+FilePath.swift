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
