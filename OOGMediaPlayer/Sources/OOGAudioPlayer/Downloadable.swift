//
//  Downloadable.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/22.
//

import Foundation

//MARK: - 音乐使用
public enum FileDownloadProgress {
    case normal
    case downloading(Double)
    case failed(Error)
    case downloaded
    
    public var isDownloaded: Bool {
        if case .downloaded = self {
            return true
        }
        return false
    }
    
    public var isDownloading: Bool {
        if case .downloading(_) = self {
            return true
        }
        return false
    }
}

 

// Bool： FALSE - 销毁，TRUE - 继续回调
public typealias DownloadStatusChangedClosure = (LocalMediaPlayable, FileDownloadProgress) -> Bool

public protocol Downloadable {
    
    /// 文件下载链接
    var fileUrlString: String? { get }
    /// 文件状态
    var downloadProgress: FileDownloadProgress  { get }
    
    /// 文件下载请求
    var downloadRequest: DownloadRequest?  { get set }
    /// 取消文件下载
    func cancelFileDownload()
}

public extension Downloadable {
    var isDownloading: Bool {
        if case .downloading(_) = downloadProgress {
            return true
        }
        return false
    }
}
