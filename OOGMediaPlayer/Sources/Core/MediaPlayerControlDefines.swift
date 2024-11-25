//
//  MediaPlayerControlDefines.swift
//  OOGMediaPlayer
//
//  Created by XinCore on 2024/11/25.
//

import Foundation


public extension IndexPath {
    var descriptionForPlayer: String {
        return "[\(section) - \(row)]"
    }
}

extension LogPrefix {
    static let mediaPlayer = "MediaPlayer"
}

public extension Notification.Name {
    
    /// 通知 - 多媒体播放器随机循环模式下的下一条目发生变化
    static let mediaPlayerControlDidChangedNextIndexPathForShuffleLoop = Notification.Name(rawValue: "com.oog.localAudioPlayerProvider.notification.didChangedNextIndexPathForShuffleLoop")
    
    /// 通知 - 已经准备好开始播放音频
    static let mediaPlayerControlAlreadyToPlayAudio = Notification.Name("com.oog.localAudioPlayerProvider.notification.alreadyToPlayAudio")
}

public typealias MediaPlayerGetUrlClosure = (Result<URL, any Error>) -> Void

extension MediaPlayerControl {
    
    public enum LoopMode: String, Codable {
        /// 无循环
        case none
        /// 顺序循环
        case order
        ///  专辑或歌单内循环
        case album
        /// 单曲循环
        case single
        /// 随机循环
        case shuffle
        
        public var userInterfaceDisplay: String {
            switch self {
            case .none: return "无循环"
            case .order: return "顺序循环"
            case .album: return "专辑循环"
            case .single: return "单曲循环"
            case .shuffle: return "随机循环"
            }
        }
    }
    
    public enum PlayerStatus: Int, Codable {
        /// 停止
        case stoped = 0
        /// 准备播放
        case prepareToPlay
        /// 播放
        case playing
        /// 暂停
        case paused
        /// 播放完成
        case finished
        /// 播放错误
        case error
        
        public func description() -> String {
            switch self {
            case .stoped:
                return "Stop"
            case .prepareToPlay:
                return "Prepare to play next"
            case .playing:
                return "Playing"
            case .paused:
                return "Pause"
            case .finished:
                return "Finished"
            case .error:
                return "Error"
            }
        }
        
        public func userInterfaceDisplay() -> String {
            switch self {
            case .stoped:
                return "停止"
            case .prepareToPlay:
                return "准备播放"
            case .playing:
                return "正在播放"
            case .paused:
                return "暂停播放"
            case .finished:
                return "播放完成"
            case .error:
                return "播放错误"
            }
        }
    }
}
