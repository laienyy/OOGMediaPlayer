//
//  OOGMediaPlayerError.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/11/15.
//

import Foundation

enum OOGMediaPlayerError {
    
    public enum MediaPlayerControlError: Error, LocalizedError {
        // MediaPlayerControl.isEnable 是 FALSE
        case isNotEnable
        // 列表不存在有效的多媒体数据 （MediaPlayable.isValid == False）
        case noInvalidItem
        // 当前播放的多媒体数据为空
        case currentItemIsNil
        // 文件已经在准备播放期间
        case alreadyBeenPreparing
        
        public var errorDescription: String? {
            switch self {
            case .isNotEnable:
                return "Player is not enable"
            case .noInvalidItem:
                return "No valid playable item for now"
            case .currentItemIsNil:
                return "Player current item indexPath is none or the indexPath is valid (at indexPath can not found media item)"
            case .alreadyBeenPreparing:
                return "File already been preparing, Now is during `Downloading` or during `prepareToPlay` step)"
            }
        }
    }
    
    public enum LocalAudioPlayerError: Error, LocalizedError {
        /// 本地文件URL错误
        case fileUrlInvalid
        /// 操作已经过期，在等待文件数据的时候，外部有新的操作
        case operationExpired
        
        public var errorDescription: String? {
            switch self {
            case .fileUrlInvalid:
                return "File url is invalid"
            case .operationExpired:
                return "Operation is expired"
            }
        }
    }
    
    public enum LocalMediaPlayerError: Error, LocalizedError {
        // 实例化 AVAduioPlayer 失败
        case generatePlayerFailed
        // 准备播放失败
        case prepareToPlayFailed
        // 获取到的 URL.isFileURL 是 false
        case sourceIsNotFileUrl
        
        public var errorDescription: String? {
            switch self {
            case .generatePlayerFailed:
                return "`LocalAudioPlayerProvider` Generate player failed"
            case .prepareToPlayFailed:
                return "`LocalAudioPlayerProvider` Prepare to play failed"
            case .sourceIsNotFileUrl:
                return "`LocalAudioPlayerProvider` Player source is not file url"
            }
        }
    }
    
    // 任务错误
    public enum TaskError: Error, LocalizedError {
        // 超时
        case timeout
        
        public var errorDescription: String? {
            switch self {
            case .timeout: return "Task Time Out"
            }
        }
    }
    
    // 下载错误
    enum DownloadError: Error, LocalizedError {
        case requestUrlInvalid
        // 请求已经释放
        case requestRelease
        
        public var errorDescription: String? {
            switch self {
            case .requestUrlInvalid:
                return "Request url is invalid"
            case .requestRelease: 
                return "Request memory was released"
            }
        }
    }
    
}
