//
//  Request.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/21.
//

import Foundation

class Request {
    
    /// 请求体
    var urlRequest: URLRequest
    /// 参数编码器
    let encoding: RequestParameterEncoding
    /// 参数
    let params: [String: AnyHashable]?
    /// 返回数据解码器
    let responseDecoder: ResponseDecoder
    
    init(api: API,
         headers: [String: String]? = nil,
         parameterEncoding: RequestParameterEncoding = UrlEncoding(),
         decoder: ResponseDecoder = JSONResponseDecoder()) throws {
        params = api.parameters
        encoding = parameterEncoding
        
        guard let url = URL(string: api.domain + api.path) else {
            throw RequestError.urlIsInvalid
        }
        
        var request = URLRequest(url: url)
        try parameterEncoding.encode(&request, parameters: params)
        if let headers = headers {
            headers.forEach { item in
                request.addValue(item.value, forHTTPHeaderField: item.key)
            }
        }
        
        urlRequest = request
        urlRequest.httpMethod = api.method.rawValue
        responseDecoder = decoder
    }
    
    func resume<T: Decodable>() async throws -> T {
        
        // 发起请求
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResposne = response as? HTTPURLResponse else {
            throw RequestError.responseError(response)
        }
        
        guard httpResposne.statusCode == 200 else {
            throw RequestError.statusCodeError(httpResposne.statusCode)
        }
        
        let model = try JSONDecoder().decode(T.self, from: data)
        return model
    }
}
