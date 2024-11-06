//
//  FileItem+Cache.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/17.
//

import Foundation

public extension FileItem {
    
    /// 根据 key 获取 FilePath
    static func getCache(key: String) -> FileItem? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        
        guard let filePath = try? JSONDecoder().decode(FileItem.self, from: data) else {
            return nil
        }
        
        return filePath
    }
    
    /// 根据 key 保存 FilePath
    func storeFilePath(key: String) {
        let jsonData = try? JSONEncoder().encode(self)
        UserDefaults.standard.set(jsonData, forKey: key)
    }
    
}
