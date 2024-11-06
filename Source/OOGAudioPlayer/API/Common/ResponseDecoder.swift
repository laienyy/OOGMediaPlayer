//
//  ResponseDecoder.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/21.
//

import Foundation

protocol ResponseDecoder {
    func decode<T: Decodable>(_ data: Data) throws -> T
}


class JSONResponseDecoder: ResponseDecoder {
    func decode<T>(_ data: Data) throws -> T where T : Decodable {
        return try JSONDecoder().decode(T.self, from: data)
    }
}
