//
//  MediaPlayerControlDelegate.swift
//  OOGMediaPlayer
//
//  Created by XinCore on 2024/11/16.
//

import Foundation


public protocol MediaPlayerControlDelegate: AnyObject {
    
    /// 将要播放，返回`false`跳过播放
    func mediaPlayerControl(_ control: MediaPlayerControl, shouldPlay indexPath: IndexPath, current: IndexPath?) -> IndexPath?
    /// 即将播放
    func mediaPlayerControl(_ control: MediaPlayerControl, willPlay indexPath: IndexPath)
    /// 已经播放
    func mediaPlayerControl(_ control: MediaPlayerControl, startPlaying indexPath: IndexPath)
  
    /// 播放器状态改变
    func mediaPlayerControlStatusDidChanged(_ control: MediaPlayerControl)
    /// 播放错误
    func mediaPlayerControl(_ control: MediaPlayerControl, playAt indexPath: IndexPath?, error: Error)
}

// 预实现，实现 Swift Protocol 可选化
public extension MediaPlayerControlDelegate {

    func mediaPlayerControlStatusDidChanged(_ control: MediaPlayerControl) { }
    func mediaPlayerControl(_ control: MediaPlayerControl, shouldPlay indexPath: IndexPath, current: IndexPath?) -> IndexPath? {
        return indexPath
    }
    func mediaPlayerControl(_ control: MediaPlayerControl, willPlay indexPath: IndexPath) { }
    func mediaPlayerControl(_ control: MediaPlayerControl, startPlaying indexPath: IndexPath) { }
}
