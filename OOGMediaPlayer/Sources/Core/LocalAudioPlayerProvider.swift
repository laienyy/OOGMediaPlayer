//
//  LocalAudioPlayerProvider.swift
//  BGMManagerSample
//
//  Created by YiYuan on 2024/10/11.
//

import UIKit
import AVFoundation

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
    /// 没有淡进
    case none
    /// 淡进一次
    case once(TimeInterval)
    /// 每次
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
    
    public override var isEnable: Bool {
        didSet {
            if !isEnable, audioPlayer?.isPlaying ?? false {
                pause()
            }
        }
    }
    
    /// 重置已经播放淡入的标志
    open func resetFadedFlag() {
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
        log(prefix: .mediaPlayer, "Check ID [\(item.resId)], have [\(preparingItems.count)] items in preparing queue")
        return preparingItems.contains(where: { $0.resId == item.resId })
    }
    
    func appendToPreparingQueue(_ item: LocalMediaPlayable) {
        preparingItems.append(item)
        log(prefix: .mediaPlayer, "Remove \(item.resId) from preparing queue")
    }
    
    func removeFromPreparingQueue(_ item: LocalMediaPlayable) {
        preparingItems.removeAll(where: { $0.resId == item.resId } )
        log(prefix: .mediaPlayer, "Remove \(item.resId) from preparing queue")
    }
    
    override func toPlay(indexPath: IndexPath) {
        super.toPlay(indexPath: indexPath)
    }
    
    /// 准备播放
    open override func prepareToPlayItem(at indexPath: IndexPath) async throws {
        try await super.prepareToPlayItem(at: indexPath)
        
        guard let item = currentItem() as? LocalMediaPlayable else {
            log(prefix: .mediaPlayer, "Prepare to play item failed, current item is nil")
            throw MediaPlayerControlError.currentItemIsNil
        }
        
        guard !isIndexPathInPreparingQueue(indexPath) else {
            // 正在下载，本轮跳出播放流程（等待下载完，会继续执行播放）
            log(prefix: .mediaPlayer, "Prepare to play item (\(indexPath.descriptionForPlayer) failed, current item is during download")
            setItemStatus(item, status: .downloading)
            throw MediaPlayerControlError.alreadyBeenPreparing
        }
        
        // 加入等待队列
        appendToPreparingQueue(item)
        setItemStatus(item, status: .downloading)
        
        // *** 等待外部返回文件URL
        let fileUrl = try await item.getLocalFileUrl()
        
        // 移出等待队列
        removeFromPreparingQueue(item)
        setItemStatus(item, status: .prepareToPlay)
        
        
        if currentItem()?.resId != media(at: indexPath)?.resId {
            // 不是当前需要播放的顺序，终止播放流程
            setItemStatus(item, status: .stoped)
            throw LocalAudioPlayerError.operationExpired
        }
        
        guard fileUrl.isFileURL else {
            setItemStatus(item, status: .error)
            log(prefix: .mediaPlayer, "Play item \(indexPath.descriptionForPlayer) failed, The url is not FileURL")
            throw LocalAudioPlayerError.fileUrlInvalid
        }
        
        let data = try Data(contentsOf: fileUrl)
        let audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer.delegate = self
        
        guard audioPlayer.prepareToPlay() else {
            setItemStatus(item, status: .error)
            throw LocalMediaPlayerError.prepareToPlayFailed
        }
        
        self.audioPlayer = audioPlayer
    }
    
    open override func pause() {
        if playerStatus == .playing {
            super.pause()
            audioPlayer?.pause()
            setCurrentItemStatus(.paused)
        }
    }
    
    /// 播放
    override open func play() {
        
        guard let audioPlayer = audioPlayer else {
            log(prefix: .mediaPlayer, "Ignore play for this time, the `AVAudioPlayer` is nil")
            return
        }
        
        guard !audioPlayer.isPlaying else {
            log(prefix: .mediaPlayer, "Ignore play for this time, the `AVAudioPlayer` is playing")
            super.setStatus(.playing)
            setCurrentItemStatus(.playing)
            return
        }
        
        super.play()
        setCurrentItemStatus(.playing)
        
        
        audioPlayer.volume = 0
        let didPlaying = audioPlayer.play()
        
        log(prefix: .mediaPlayer, didPlaying ? "Did playing \(currentItem())" : "Playing failed \(currentItem())")
        
//        guard playing else {
//            return
//        }
        
        switch playFadeMode {
        case .none:
            audioPlayer.volume = volume
        case .once(let duration):
            guard !self.isFaded else {
                audioPlayer.volume = volume
                break
            }
            audioPlayer.setVolume(volume, fadeDuration: duration)
            
        case .each(let duration):
            audioPlayer.setVolume(volume, fadeDuration: duration)
        }
        
        isFaded = true
        
        
        
        guard let indexPath = currentIndexPath else {
            log(prefix: .mediaPlayer, "ERROR, Can not to post `DidStartPlayingAudio` Notification and call delegate, because currentIndexPath is nil")
            return
        }
        
        DispatchQueue.main.async {
            var userInfo = ["indexPath" : indexPath] as [String : Any]
            userInfo["album"] = self.album(at: indexPath.section)
            userInfo["audio"] = self.media(at: indexPath)
            NotificationCenter.default.post(name: .oogAudioPlayerDidStartPlayAudioNotification, object: self, userInfo: userInfo)
            self.delegate?.mediaPlayerControl(self, startPlaying: indexPath)
        }
        
    }

    /// 停止播放
    override open func stop() {
        super.stop()
        audioPlayer?.stop()
        audioPlayer = nil
        setCurrentItemStatus(.stoped)
        currentIndexPath = nil
    }

}

extension LocalAudioPlayerProvider {
    func setCurrentItemStatus(_ status: LocalMediaStatus) {
        guard let item = currentItem() as? LocalMediaPlayable else {
            return
        }
        // 选出所有id相同的多媒体
        
        let items = items.flatMap({ $0.mediaList }).filter({ $0.resId == item.resId }) as? [LocalMediaPlayable]
        for item in items ?? [] {
            setItemStatus(item, status: status)
        }
    }
    
    func setItemStatus(_ item: LocalMediaPlayable, status: LocalMediaStatus) {
        let sameItems = items.flatMap({ $0.mediaList })
                             .compactMap({ $0 as? LocalMediaPlayable })
                             .filter { $0.resId == item.resId }
        
        let itemsDescription = sameItems.map({ "\($0)" }).joined(separator: "\n\t")
        log(prefix: .mediaPlayer, "Set status \(status) to: [\n\t\(itemsDescription)\n]")
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
        log(prefix: .mediaPlayer, "Decode error", error as Any)
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
