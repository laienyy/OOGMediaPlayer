//
//  FileManager+Shortcut.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/17.
//

import Foundation

public extension FileManager {
    
    func write(data: Data, to url: URL, overwrite: Bool = true, createDirectoryAuto: Bool = true) throws {
        
        var isDirectory: ObjCBool = true
        let dire = url.deletingLastPathComponent()
        if !fileExists(atPath: dire.relativePath, isDirectory: &isDirectory) {
            try createDirectory(at: dire, withIntermediateDirectories: true)
        }
        
        try data.write(to: url, options: overwrite ? .init() : .withoutOverwriting)
    }
}
