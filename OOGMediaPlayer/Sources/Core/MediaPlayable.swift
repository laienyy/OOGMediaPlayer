//
//  MediaPlayable.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/17.
//

import Foundation

public protocol MediaAlbum: Equatable, Codable {
    associatedtype MediaType: MediaPlayable
    var id: Int { get }
    var mediaList: [MediaType] { get }
}

public protocol MediaPlayable: Codable {
    var resId: Int { get }
    // 多媒体名称
    var fileName: String { get }
    // 当前是否无效
    var isValid: Bool { get }
}

