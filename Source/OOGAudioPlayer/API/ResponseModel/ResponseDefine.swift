//
//  ResponseDefine.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/11/4.
//

import Foundation

fileprivate func oogError(code: Int) -> Error? {
    return nil
}

/// 单个对象返回值
struct JsonResponse<T: Decodable>: Decodable {
    var code: Int?
    var message: String?
    var data: T?
    
    func error() -> Error? { oogError(code: code ?? 0) }
}

/// 对象列表返回值
struct JsonArrayResponse<T: Decodable>: Decodable {
    var code: Int?
    var message: String?
    var data: [T]?
    
    func error() -> Error? { oogError(code: code!) }
}
