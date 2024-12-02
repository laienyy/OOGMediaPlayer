//
//  FileRootDirectory.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/17.
//

import Foundation

/// 文件根目录
public enum FileRootDirectory: Int, Codable {
    
    case document
    case cache
    
    public func asString() -> String {
        switch self {
        case .document:
            return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        case .cache:
            return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        }
    }
}
