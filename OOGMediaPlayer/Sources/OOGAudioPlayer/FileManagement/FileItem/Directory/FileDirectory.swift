//
//  FileDirectory.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/17.
//

import Foundation

// 文件夹
public struct FileDirectory: Codable {
    
    public var string: String
    
    public init(string: String) {
        self.string = string
    }
    
    // 移除反斜杠前缀
    public func asString() -> String {
        let str = string
        // 添加斜杠前缀
        return str.hasPrefix("/") ? str : ("/" + str)
    }
    
}
