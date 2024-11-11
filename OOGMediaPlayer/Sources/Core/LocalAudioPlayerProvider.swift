//
//  LocalAudioPlayerProvider.swift
//  BGMManagerSample
//
//  Created by YiYuan on 2024/10/11.
//

import UIKit
import AVFoundation

public enum LocalMediaStatus: Int, Codable {
    case idle
    case downloading
    case prepareToPlay
    case playing
    case paused
    case stoped
    case error
}

public typealias StatusChangedClosure = (any LocalMediaPlayable, LocalMediaStatus) -> Bool

public protocol LocalMediaPlayable: MediaPlayable, Downloadable {
    
    /// 状态
    var status: LocalMediaStatus { get set }
    
    
    /// 文件状态变化
    var statusChangedActions: [AnyHashable: StatusChangedClosure]  { get set }
    
    // 添加状态变化的回调
    func observeStatusChanged(_ observer: AnyHashable, _ action: @escaping StatusChangedClosure)
    // 释放回调
    func removeStatusObserver(_ observer: AnyHashable)
    
    /// 设置新状态
    func setNewPlayerStatus(_ status: LocalMediaStatus)
    
    // 获取多媒体本地文件URL
    func getLocalFileUrl() async throws -> URL
}

/// 本地音频淡出淡入模式
public enum LocalAudioVolumeFadeMode {
    case none
    case first(TimeInterval)
    case each(TimeInterval)
}

public enum LocalMediaPlayerError: Error, LocalizedError {
    case generatePlayerFailed
    case prepareToPlayFailed
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

public extension Notification.Name {
    
    // 通知 - 已经开始播放音频
    static let oogAudioPlayerDidStartPlayAudioNotification = Notification.Name(rawValue: "com.oog.localAudioPlayerProvider.notification.didStartPlayAudio")
}

open class LocalAudioPlayerProvider: MediaPlayerControl {
    
    public var audioPlayer: AVAudioPlayer?
    
    open var playFadeMode: LocalAudioVolumeFadeMode = .none
    open var isFaded: Bool = false
    
    func resetFadedFlag() {
        isFaded = false
    }
    
    open var currentTime: TimeInterval { audioPlayer?.currentTime ?? 0 }
    open var duration: TimeInterval { audioPlayer?.duration ?? 0 }
    open var volume: Float = 1.0 {
        didSet {
            audioPlayer?.volume = volume
        }
    }
    
    open var isRateEnable: Bool { return audioPlayer?.enableRate ?? false }
    
    open var rate: Float {
        get {
            return audioPlayer?.rate ?? 0
        }
        set {
            audioPlayer?.rate = newValue
        }
    }
    
    var preparingItems = [LocalMediaPlayable]()
    
    /// 检查indexPath是否正在获取（下载）音频本地文件
    func isIndexPathInPreparingQueue(_ indexPath: IndexPath) -> Bool {
        guard let item = media(at: indexPath) else {
            return false
        }
        return preparingItems.contains(where: { $0.resId == item.resId })
    }
    
    func appendToPreparingQueue(_ item: LocalMediaPlayable) {
        preparingItems.append(item)
    }
    
    func removeFromPreparingQueue(_ item: LocalMediaPlayable) {
        preparingItems.removeAll(where: { $0.resId == item.resId } )
    }
    
    override func toPlay(indexPath: IndexPath) {
        super.toPlay(indexPath: indexPath)
    }
    
    /// 准备播放
    open override func prepareToPlayItem(at indexPath: IndexPath) async throws {
        try await super.prepareToPlayItem(at: indexPath)
        
        let item: LocalMediaPlayable = try await MainActor.run {
            
            guard let item = currentItem() as? LocalMediaPlayable else {
                log(prefix: .mediaPlayer, "Prepare to play item failed, current item is nil")
                throw MediaPlayerControlError.currentItemIsNil
            }
            
            guard !isIndexPathInPreparingQueue(indexPath) else {
                // 正在下载，本轮跳出播放流程（等待下载完，会继续执行播放）
                log(prefix: .mediaPlayer, "Prepare to play item (\(indexPath.descriptionForPlayer) failed, current item is during download")
                setItemStatus(item, status: .stoped)
                throw MediaPlayerControlError.alreadyBeenPreparing
            }
            
            // 加入等待队列
            appendToPreparingQueue(item)
            setItemStatus(item, status: .downloading)
            return item
        }
        
        // *** 等待外部返回文件URL
        let fileUrl = try await item.getLocalFileUrl()
        
        // 移出等待队列
        removeFromPreparingQueue(item)
        setItemStatus(item, status: .prepareToPlay)
        
        
        if let current = currentIndexPath, current != indexPath {
            // 不是当前需要播放的顺序，终止播放流程
            setItemStatus(item, status: .stoped)
            return
        }
        
        guard fileUrl.isFileURL else {
            setItemStatus(item, status: .error)
            log(prefix: .mediaPlayer, "Play item \(indexPath.descriptionForPlayer) failed, The url is not FileURL")
            return
        }
        
        let data = try Data(contentsOf: fileUrl)
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.delegate = self
        
        guard let player = self.audioPlayer else {
            setItemStatus(item, status: .error)
            throw LocalMediaPlayerError.prepareToPlayFailed
        }
        
        guard player.prepareToPlay() else {
            setItemStatus(item, status: .error)
            throw LocalMediaPlayerError.prepareToPlayFailed
        }
    }
    
    open override func pause() {
        super.pause()
        audioPlayer?.pause()
        setCurrentItemStatus(.paused)
    }
    
    /// 播放
    override open func play() {
        super.play()
        
        guard let playing = audioPlayer?.isPlaying, !playing else {
            log(prefix: .mediaPlayer, "Ignore play for this time, the player is playing")
            setCurrentItemStatus(.error)
            return
        }
        audioPlayer?.play()
        setCurrentItemStatus(.playing)
        
        switch playFadeMode {
        case .none:
            audioPlayer?.volume = volume
        case .first(let duration):
            guard !isFaded else {
                audioPlayer?.volume = volume
                return
            }
            audioPlayer?.volume = 0
            audioPlayer?.setVolume(volume, fadeDuration: duration)
            
        case .each(let duration):
            audioPlayer?.volume = 0
            audioPlayer?.setVolume(volume, fadeDuration: duration)
        }
        
        isFaded = true
        
        guard let indexPath = currentIndexPath else {
            log(prefix: .mediaPlayer, "ERROR, Can not to post `DidStartPlayingAudio` Notification and call delegate, because currentIndexPath is nil")
            return
        }
        var userInfo = ["indexPath" : indexPath] as [String : Any]
        userInfo["album"] = album(at: indexPath.section)
        userInfo["audio"] = media(at: indexPath)
        NotificationCenter.default.post(name: .oogAudioPlayerDidStartPlayAudioNotification, object: self, userInfo: userInfo)
        delegate?.mediaPlayerControl(self, startPlaying: indexPath)
    }
    
    /// 停止播放
    override open func stop() {
        super.stop()
        audioPlayer?.stop()
        setCurrentItemStatus(.stoped)
        currentIndexPath = nil
    }

}

extension LocalAudioPlayerProvider {
    func setCurrentItemStatus(_ status: LocalMediaStatus) {
        guard let item = currentItem() as? LocalMediaPlayable else {
            return
        }
        setItemStatus(item, status: status)
    }
    
    func setItemStatus(_ item: LocalMediaPlayable, status: LocalMediaStatus) {
        let sameItems = self.items.flatMap({ $0.mediaList }).compactMap({ $0 as? LocalMediaPlayable }) .filter { $0.resId == item.resId }
        
        DispatchQueue.main.async {
            sameItems.forEach {
                $0.setNewPlayerStatus(status)
            }
        }

    }
}

extension LocalAudioPlayerProvider: AVAudioPlayerDelegate {

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        setStatus(.finished)
        playNext()
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        setStatus(.error)
        log(prefix: .mediaPlayer, "Decode error", error)
    }
}

enum TaskError: Error {
    case timeout
}

func excute<T>(timeout: TimeInterval, task: @escaping () async throws -> T) async throws -> T {
    let task = Task {
        try await task()
    }
    
    Task {
        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
        task.cancel()
    }
    do {
        return try await task.value
    } catch let error {
        throw task.isCancelled ? TaskError.timeout : error
    }
}
