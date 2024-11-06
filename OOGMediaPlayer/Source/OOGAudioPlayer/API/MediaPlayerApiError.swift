//
//  MediaPlayerApiError.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/11/4.
//

import Foundation


enum RequestError: Error {
    /// URL
    case urlIsInvalid
    /// 获取到的 `Response` 不是 `HTTPURLResponse`
    case responseError(_ response: URLResponse)
    /// HTTP状态码错误
    case statusCodeError(_ responseCode: Int)
}
