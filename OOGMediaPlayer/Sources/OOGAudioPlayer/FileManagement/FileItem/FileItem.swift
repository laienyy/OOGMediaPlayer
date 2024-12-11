//
//  FileItem.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/17.
//

import Foundation

/// 文件信息
public struct FileItem: Codable {
    
    /// 根目录
    public let root: FileRootDirectory
    /// 自定义目录
    public let directory: FileDirectory
    /// 文件名
    public let fileName: String
    
    public init(root: FileRootDirectory, directory: FileDirectory, fileName: String) {
        self.root = root
        self.directory = directory
        self.fileName = fileName
    }
    
}


public extension FileItem {
    
    /// 返回文件完整路径字符串
    func asFilePathString() -> String {
        let path = root.asString() + directory.asString() + "/" + fileName
        return path
    }
    
    /// 返回文件相对路径字符串
    func asFileRelativePathString() -> String {
        let path = directory.asString() + "/" + fileName
        return path
    }
    
    /// 返回`本地文件路径`类型的 URL
    func asFilePathUrl() -> URL {
        return URL(fileURLWithPath: asFilePathString())
    }
    
    /// 讲 data 写入对应文件路径
    func write(data: Data, overwrite: Bool = true) throws {
        let url = asFilePathUrl()
        try FileManager.default.write(data: data, to: url, overwrite: overwrite, createDirectoryAuto: true)
    }
    
    /// 根据文件路径获取 Data
    func getDataFromDisk() -> Data? {
        let manager = FileManager.default
        // 检查是否存在文件，以及文件大小是否 > 0
        guard manager.fileExists(atPath: asFilePathString()), fileSize > 0 else {
            return nil
        }
        return FileManager.default.contents(atPath: asFilePathString())
    }
    
    func removeDataFromDisk() throws {
        try FileManager.default.removeItem(at: asFilePathUrl())
    }
}

public extension FileItem {
    
    /// 文件大小
    var fileSize: Int64 {
        return getFileAttributes()?[.size] as? Int64 ?? 0
    }
    
    /// 是否存在文件，以及文件大小是否不为 0
    func isDataValid() -> Bool {
        let isValid = fileSize > 0
        return isValid
    }
    
    /// 获取文件属性
    func getFileAttributes() -> [FileAttributeKey : Any]? {
        // 获取文件属性
        let attributes = try? FileManager.default.attributesOfItem(atPath: asFilePathString())
        return attributes
    }
    
}
