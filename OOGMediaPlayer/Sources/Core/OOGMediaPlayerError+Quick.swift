//
//  OOGMediaPlayerError+Quick.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/12/5.
//

import Foundation

public extension Error {
    
    func isTimeoutError() -> Bool {
        if let error = self as? OOGMediaPlayerError.DownloadError {
            return error == .timeout
        } else if let error = self as? OOGMediaPlayerError.TaskError {
            return error == .timeout
        } else {
            let error = self as NSError
            return error.code == NSURLErrorTimedOut
        }
    }
    
    func isCanceledError() -> Bool {
        if let error = self as? OOGMediaPlayerError.DownloadError {
            return error == .canceled
        } else {
            let error = self as NSError
            return error.code == NSURLErrorCancelled
        }
    }
}
