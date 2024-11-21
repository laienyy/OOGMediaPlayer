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
    func getLocalFileUrl(timeoutInterval: TimeInterval) async throws -> URL
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
    
    // 淡入模式
    open var playFadeMode: LocalAudioVolumeFadeMode = .none
    // 是否已淡入，可通过 resetFadedFlag 重置（ 为 LocalAudioVolumeFadeMode.once 时所使用 ）
    open var isFaded: Bool = false
    
    // 获取文件Data的超时时间
    open var getFileTimeoutInterval: TimeInterval = 60
    
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
        log(prefix: .mediaPlayer, "Add Meida ID ( \(item.resId) ) to preparing queue")
    }
    
    func removeFromPreparingQueue(_ item: LocalMediaPlayable) {
        preparingItems.removeAll(where: { $0.resId == item.resId } )
        log(prefix: .mediaPlayer, "Remove Meida ID [ \(item.resId) ] from preparing queue")
    }
    
    /// 准备播放
    open override func prepareToPlayItem(at indexPath: IndexPath) async throws {
        try await super.prepareToPlayItem(at: indexPath)
        
        guard let item = currentItem() as? LocalMediaPlayable else {
            log(prefix: .mediaPlayer, "Prepare to play item failed, current item is nil")
            throw OOGMediaPlayerError.MediaPlayerControlError.currentItemIsNil
        }
        
        guard !isIndexPathInPreparingQueue(indexPath) else {
            // 正在下载，本轮跳出播放流程（等待下载完，会继续执行播放）
            log(prefix: .mediaPlayer, "Prepare to play item (\(indexPath.descriptionForPlayer) failed, current item is during download")
            await MainActor.run {
                setItemStatus(item, status: .downloading)
            }
//            throw OOGMediaPlayerError.MediaPlayerControlError.alreadyBeenPreparing
            return
        }
        
        // 加入等待队列
        appendToPreparingQueue(item)
        await MainActor.run {
            setItemStatus(item, status: .downloading)
        }
        
        var fileUrl: URL
        do {
            // *** 等待外部返回文件URL
            fileUrl = try await item.getLocalFileUrl(timeoutInterval: getFileTimeoutInterval)
        } catch let error {
            removeFromPreparingQueue(item)
            throw error
        }
        
        // 移出等待队列
        removeFromPreparingQueue(item)
        await MainActor.run {
            setItemStatus(item, status: .prepareToPlay)
        }
        
        if currentItem()?.resId != media(at: indexPath)?.resId {
            // 不是当前需要播放的顺序，终止播放流程
            await MainActor.run {
                setItemStatus(item, status: .stoped)
            }
            throw OOGMediaPlayerError.LocalAudioPlayerError.operationExpired
        }
        
        guard fileUrl.isFileURL else {
            await MainActor.run {
                setItemStatus(item, status: .error)
            }
            log(prefix: .mediaPlayer, "Play item \(indexPath.descriptionForPlayer) failed, The url is not FileURL")
            throw OOGMediaPlayerError.LocalAudioPlayerError.fileUrlInvalid
        }
        
        let data = try Data(contentsOf: fileUrl)
        let audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer.delegate = self
        
        guard audioPlayer.prepareToPlay() else {
            await MainActor.run {
                setItemStatus(item, status: .error)
            }
            throw LocalMediaPlayerError.prepareToPlayFailed
        }
        
        self.audioPlayer = audioPlayer
        
    }
    
    open override func pause() {
        super.pause()
        audioPlayer?.pause()
        setCurrentItemStatus(.paused)
    }
    
    /// 播放
    override open func play() {
        
        guard let indexPath = currentIndexPath else {
            log(prefix: .mediaPlayer, "[ERR] Try to play failed, the `currentIndexPath` is nil")
            return
        }
        
        guard isEnable else {
            log(prefix: .mediaPlayer, "Try to play failed, the `isEnable` is false")
            return
        }
        
        guard let audioPlayer = audioPlayer else {

            if playerStatus == .prepareToPlay {
                log(prefix: .mediaPlayer, "Ignore play for this time, the `AVAudioPlayer` is preparing")
                return
            }
            
            if isExistsValidMedia() {
                playNext()
            } else {
                log(prefix: .mediaPlayer, "Ignore play for this time, there have no valid media to play")
            }
            
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
        
        // 更新`indexPath` 可能由delegate返回一个新的
        delegate?.mediaPlayerControl(self, willPlay: indexPath)
        
        audioPlayer.volume = 0
        let didPlaying = audioPlayer.play()
        
        log(prefix: .mediaPlayer, didPlaying ? "Did playing \(String(describing: currentItem()))" : "Playing failed \(String(describing: currentItem()))")
        
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
    
    override func playError(at indexPath: IndexPath?, error: any Error) {
        super.playError(at: indexPath, error: error)
        if let indexPath = indexPath, let item = media(at: indexPath) as? LocalMediaPlayable {
            setItemStatus(item, status: .error)
        }
    }

}

extension LocalAudioPlayerProvider {
    func setCurrentItemStatus(_ status: LocalMediaStatus) {
        guard let item = currentItem() as? LocalMediaPlayable else {
            return
        }
        // 选出所有id相同的多媒体
        
        let items = getItems().flatMap({ $0.mediaList }).filter({ $0.resId == item.resId }) as? [LocalMediaPlayable]
        for item in items ?? [] {
            setItemStatus(item, status: status)
        }
    }
    
    func setItemStatus(_ item: LocalMediaPlayable, status: LocalMediaStatus) {
        let sameItems = getItems().flatMap({ $0.mediaList })
                             .compactMap({ $0 as? LocalMediaPlayable })
                             .filter { $0.resId == item.resId }
        
        let itemsDescription = sameItems.map({ "\($0)" }).joined(separator: "\n\t")

        log(prefix: .mediaPlayer, "Set status \(status) to: \(item)")
        
        if Thread.isMainThread {
            sameItems.forEach {
                $0.setNewPlayerStatus(status)
            }
        } else {
            DispatchQueue.main.sync {
                sameItems.forEach {
                    $0.setNewPlayerStatus(status)
                }
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
        
        if let error = error {
            playError(at: currentIndexPath, error: error)
        }
    }
}


func excute<T>(timeout: TimeInterval, task: @escaping () async throws -> T) async throws -> T {
    
    let fetchTask = Task {
        let result = try await task()
        try Task.checkCancellation()
        return result
    }
        
    let timeoutTask = Task {
        try await Task.sleep(nanoseconds: UInt64(timeout) * NSEC_PER_SEC)
        // 取消正常流程需执行的Task
        fetchTask.cancel()
        // 返回超时Error
        throw OOGMediaPlayerError.TaskError.timeout
    }
    
    do {
        let result = try await fetchTask.value
        timeoutTask.cancel()
        return result
    } catch let error {
        throw fetchTask.isCancelled ? OOGMediaPlayerError.TaskError.timeout : error
    }
}
