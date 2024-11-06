//
//  API.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/21.
//

import Foundation

protocol API {
    var method: ApiMethod { get }
    var parameters: [String: AnyHashable]? { get }
    
    var domain: String { get }
    var path: String { get }
    
    func asURL() -> URL
}
