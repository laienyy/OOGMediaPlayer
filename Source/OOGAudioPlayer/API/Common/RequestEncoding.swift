//
//  RequestEncoding.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/21.
//

import Foundation

protocol RequestParameterEncoding {

    func encode(_ request: inout URLRequest, parameters: [String: AnyHashable]?) throws
}

enum ParameterEncodingError: Error {
    case EncodingFailed
    case urlInvalid
}


class UrlEncoding: RequestParameterEncoding {
    
    func encode(_ request: inout URLRequest, parameters: [String: AnyHashable]?) throws {
        
        guard let params = parameters else {
            return
        }
        
        let paramsStr = params.map({ "\($0.key)=\($0.value)"}).joined(separator: "&")
        guard let urlString = request.url?.absoluteString.appending("?" + paramsStr) else {
            throw ParameterEncodingError.EncodingFailed
        }
        
        guard let urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw ParameterEncodingError.EncodingFailed
        }
        
        guard let url = URL(string: urlString) else {
            throw ParameterEncodingError.urlInvalid
        }
        
        request.url = url
    }
}
