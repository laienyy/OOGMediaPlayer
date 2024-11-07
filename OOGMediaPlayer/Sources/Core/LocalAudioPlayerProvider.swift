//
//  LocalAudioPlayerProvider.swift
//  BGMManagerSample
//
//  Created by YiYuan on 2024/10/11.
//

import UIKit
import AVFoundation
import AVFAudio

public enum LocalMediaStatus {
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
    
    var id: Int { get }
    
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

open class LocalAudioPlayerProvider: MediaPlayerControl {
    
    var player: AVAudioPlayer?
    
    open var currentTime: TimeInterval { player?.currentTime ?? 0 }
    open var duration: TimeInterval { player?.duration ?? 0 }
    open var volumn: Float = 1.0 {
        didSet {
            player?.volume = volumn
        }
    }
    
    open var isRateEnable: Bool { return player?.enableRate ?? false }
    
    open var rate: Float {
        get {
            return player?.rate ?? 0
        }
        set {
            player?.rate = newValue
        }
    }
    
    var preparingItems = [LocalMediaPlayable]()
    
    /// 检查indexPath是否正在获取（下载）音频本地文件
    func isIndexPathInPreparingQueue(_ indexPath: IndexPath) -> Bool {
        guard let item = item(at: indexPath) else {
            return false
        }
        return preparingItems.contains(where: { $0.id == item.id})
    }
    
    func appendToPreparingQueue(_ item: LocalMediaPlayable) {
        preparingItems.append(item)
    }
    
    func removeFromPreparingQueue(_ item: LocalMediaPlayable) {
        preparingItems.removeAll(where: { $0.id == item.id } )
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
        
        // 判断是否正在播放
        guard currentIndexPath != nil else {
            log(prefix: .mediaPlayer, "Current item (\(indexPath.descriptionForPlayer) is already playing")
            return
        }
        
        
        guard !isIndexPathInPreparingQueue(indexPath) else {
            // 正在下载，本轮跳出播放流程（等待下载完，会继续执行播放）
            log(prefix: .mediaPlayer, "Prepare to play item (\(indexPath.descriptionForPlayer) failed, current item is during download")
            setItemStatus(item, status: .stoped)
            return
        }
        
        // 加入等待队列
        appendToPreparingQueue(item)
        setItemStatus(item, status: .downloading)
        
        // 等待外部返回文件URL
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
        player = try AVAudioPlayer(data: data)
        player?.delegate = self
        player?.rate = 2
        player?.volume = volumn
        
        guard let player = self.player else {
            setItemStatus(item, status: .error)
            throw LocalMediaPlayerError.prepareToPlayFailed
        }
        
        guard player.prepareToPlay() else {
            setItemStatus(item, status: .error)
            throw NSError(domain: "[AVAudioPlayer prepareToPlay] failed", code: 0, userInfo: nil)
        }
    }
    
    open override func pause() {
        super.pause()
        player?.pause()
        setCurrentItemStatus(.paused)
    }
    
    /// 播放
    override open func play() {
        super.play()
        
        guard let playing = player?.isPlaying, !playing else {
            log(prefix: .mediaPlayer, "Ignore play for this time, the player is playing")
            setCurrentItemStatus(.error)
            return
        }
        player?.play()
        setCurrentItemStatus(.playing)
        
        delegate?.mediaPlayerControl(self, startPlaying: currentIndexPath!)
    }
    
    /// 停止播放
    override open func stop() {
        super.stop()
        player?.stop()
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
        let sameItems = items.flatMap({ $0.mediaList }).compactMap({ $0 as? LocalMediaPlayable }) .filter { $0.id == item.id }
        sameItems.forEach {
            $0.setNewPlayerStatus(status)
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

public extension LocalAudioPlayerProvider {
    static func dukeOtherAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Set duck other audio, error:", error)
        }
    }

    static func mixOtherAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Set mix other audio, error:", error)
        }
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
