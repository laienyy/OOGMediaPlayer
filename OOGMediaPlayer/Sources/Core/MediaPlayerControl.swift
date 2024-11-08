//
//  MediaPlayerControl.swift
//  BGMManagerSample
//
//  Created by YiYuan on 2024/10/10.
//

import UIKit
import AVFoundation

extension LogPrefix {
    static let mediaPlayer = "MediaPlayer"
}

func performOnMainThread(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
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


public protocol MediaPlayerProviderDelegate: AnyObject {
    
    /// 将要播放，返回`false`跳过播放
    func mediaPlayerControl(_ provider: MediaPlayerControl, shouldPlay indexPath: IndexPath, current: IndexPath?) -> IndexPath?
    /// 即将播放
    func mediaPlayerControl(_ provider: MediaPlayerControl, willPlay indexPath: IndexPath)
    /// 已经播放
    func mediaPlayerControl(_ provider: MediaPlayerControl, startPlaying indexPath: IndexPath)
  
    /// 播放器状态改变
    func mediaPlayerControlStatusDidChanged(_ provider: MediaPlayerControl)
    /// 播放错误
    func mediaPlayerControl(_ provider: MediaPlayerControl, playAt indexPath: IndexPath?, error: Error)
}

public extension MediaPlayerProviderDelegate {
    
    /**
     * 将协议可选化
     */
    func mediaPlayerControlStatusDidChanged(_ provider: MediaPlayerControl) { }
    func mediaPlayerControl(_ provider: MediaPlayerControl, shouldPlay indexPath: IndexPath, current: IndexPath?) -> IndexPath? {
        return indexPath
    }
    func mediaPlayerControl(_ provider: MediaPlayerControl, willPlay indexPath: IndexPath) { }
    func mediaPlayerControl(_ provider: MediaPlayerControl, startPlaying indexPath: IndexPath) { }
}

public enum MediaPlayerControlError: Error, LocalizedError {
    case noInvalidItem
    case currentItemIsNil
    case sourceTypeInvalid
    // 文件已经在准备播放期间
    case alreadyBeenPreparing
    
    public var errorDescription: String? {
        switch self {
        case .noInvalidItem:
            return "No valid playable item for now"
        case .currentItemIsNil:
            return "Player current item indexPath is none or the indexPath is valid (at indexPath can not found media item)"
        case .sourceTypeInvalid:
            return "Source type is wrong"
        case .alreadyBeenPreparing:
            return "File already been preparing (Downloading or some another reason)"
        }
    }
}

open class MediaPlayerControl: NSObject {
    
    public struct HistoryItem {
        public var media: any MediaPlayable
        public var indexPath: IndexPath
    }
    
    public enum PlayDirection {
        // 指定的条目
        case specified
        // 下一个条目
        case next
        // 上一个条目
        case previous
    }
    
    public weak var delegate: MediaPlayerProviderDelegate?
    
    /// 自动播放
    public var playAutomatically: Bool = true
    /// 播放器状态
    public var playerStatus: PlayerStatus = .stoped
    /// 循环模式
    public var loopMode: LoopMode = .order
    
    /// 播放历史
    public var history: [HistoryItem] = []
    /// 当前播放位置，停止时为`nil`
    public var currentIndexPath: IndexPath? {
        didSet {
            log(prefix: .mediaPlayer, "CurrentIndexPath: \(currentIndexPath?.description ?? "nil")")
        }
    }
    
    
    /// 最后一次播放的方向
    public var lastPlayDirection = PlayDirection.next
    
    /// 多媒体条目
    var items: [any MediaAlbum] = .init()
    
    func getItems() -> [any MediaAlbum] {
        return items
    }
    
    /**
     根据 Media 重置 `CurrentIndexPath`，
     
        - Parameters:
            - media: 目标
            - playFirstIfNotCatch: 未找到当前播放的时候是否自动播放
     */
    open func resetCurrentIndexBy(_ media: MediaPlayable, playFirstIfNotCatch: Bool = false) {
        currentIndexPath = indexPathOf(mediaID: media.id)
        
        if currentIndexPath == nil, playFirstIfNotCatch, let indexPath = getValidMediaIndexPaths().first {
            play(indexPath: indexPath)
        }
    }
    
    /// 获取上一条数据
    open  func getHistoryLastItem() -> MediaPlayable? {
        return history.last?.media
    }
    
    /// 获取当前播放音频
    open func currentItem() -> MediaPlayable? {
        guard let indexPath = currentIndexPath else {
            return nil
        }
        
        return item(at: indexPath)
    }
    
    /**
     *  刷新播放列表
     *
     *  调用这个函数会重新定位 `currentIndexPath`，未定位到并`playAutomatically` = `true` 时，会重新从首歌有效多媒体开始播放
     */
    open func reloadData(_ items: [any MediaAlbum], playAutomatically: Bool = false) {
        // 删除历史记录
        history.removeAll()
        
        let playingMedia = currentItem()
        
        self.items = items
        self.playAutomatically = playAutomatically
        
        if let media = playingMedia {
            // 重新定位正在播放的歌曲的下标
            resetCurrentIndexBy(media, playFirstIfNotCatch: playAutomatically)
        }
        
        guard playAutomatically, currentIndexPath == nil else {
            return
        }
        
        playNext()
    }
    
    /// 播放下一条
    open func playNext() {
        lastPlayDirection = .next
        guard let indexPath = getNextMediaIndexPath() else {
            log(prefix: .mediaPlayer, "Play forward failed, there is no `indexPath` specified")
            playError(at: nil, error: MediaPlayerControlError.noInvalidItem)
            return
        }
        toPlay(indexPath: indexPath)
    }
    
    /// 播放上一条
    open func playPrevious() {
        lastPlayDirection = .previous
        guard let indexPath = getBackwardIndexPath() else {
            log(prefix: .mediaPlayer, "Play backward failed, there is no `indexPath` specified")
            playError(at: nil, error: MediaPlayerControlError.noInvalidItem)
            return
        }
        toPlay(indexPath: indexPath)
    }
    
    /// 播放指定索引 （不受`loopModel`影响）
    open func play(indexPath: IndexPath) {
        lastPlayDirection = .specified
        toPlay(indexPath: indexPath)
    }
    
    /// 根据索引播放
    func toPlay(indexPath: IndexPath) {
        
        
        log(prefix: .mediaPlayer, "Should play item at - (\(indexPath.section), \(indexPath.row))")
        
        // 暂停当前播放
        stop()
        
        guard let next = delegate?.mediaPlayerControl(self, shouldPlay: indexPath, current: currentIndexPath) else {
            log(prefix: .mediaPlayer, "Play next item failed, there is no `indexPath` specified")
            playError(at: nil, error: MediaPlayerControlError.noInvalidItem)
            return
        }
        currentIndexPath = next
        
        // 更新`indexPath` 可能由delegate返回一个新的
        delegate?.mediaPlayerControl(self, willPlay: next)
        
        // 准备开始播放
        Task {
            do {
                try await prepareToPlayItem(at: next)
                await MainActor.run {
                    alreadyToPlay(next)
                }
            } catch let error {
                playError(at: next, error: error)
                return
            }
        }
        
    }
    
    /// 已经准备好播放，需要判断
    private func alreadyToPlay(_ indexPath: IndexPath) {

        let next = indexPath
        guard self.currentIndexPath?.elementsEqual(next) ?? true else {
            // 全局当前索引 != 本次流程需执行索引
            let msg = "Play next item failed, the `currentIndexPath` is changed, Should play: \(self.currentIndexPath?.descriptionForPlayer ?? "Nil"), Now: \(next.descriptionForPlayer)"
            log(prefix: .mediaPlayer, msg)
            return
        }
        
        log(prefix: .mediaPlayer, "Play item at \(next.descriptionForPlayer) - \(currentItem()?.fileName ?? "unknown") (ID:\(currentItem()?.id ?? -1))")
        
        if let item = item(at: next) {
            history.append(.init(media: item, indexPath: next))
        }
        // 播放
        play()
    }
    
    
    /// 准备播放
    open func prepareToPlayItem(at indexPath: IndexPath) async throws {
        setStatus(.prepareToPlay)
    }
    
    open func play() {
        setStatus(.playing)
    }
    
    open func pause() {
        setStatus(.paused)
    }
    
    open func stop() {
        setStatus(.stoped)
    }

    func playError(at indexPath: IndexPath?, error: any Error) {
        if indexPath != nil, indexPath == currentIndexPath {
            setStatus(.error)
        }
        if lastPlayDirection == .previous {
            delegate?.mediaPlayerControl(self, playAt: indexPath, error: error)
        }
    }
}

public extension MediaPlayerControl {
    func setStatus(_ status: PlayerStatus) {
        DispatchQueue.main.async {
            self.playerStatus = status
            self.delegate?.mediaPlayerControlStatusDidChanged(self)
        }
    }
}

public extension MediaPlayerControl {
    
    func indexPathOf(mediaID: Int) -> IndexPath? {
        for section in items.enumerated() {
            if let index = section.element.mediaList.firstIndex(where: { $0.id == mediaID }) {
                return .init(row: index, section: section.offset)
            }
        }
        return nil
    }
    
    func item(at indexPath: IndexPath) -> MediaPlayable? {
        guard isValidIndexPath(indexPath) else {
            log(prefix: .mediaPlayer, "IndexPath is out of range", indexPath, items.count)
            return nil
        }
        
        return items[indexPath.section].mediaList[indexPath.row]
    }
    
    /// 获取基于当前索引的前一个索引，返回`none` =  需停止播放
    func getBackwardIndexPath() -> IndexPath? {
        guard isExistsValidMedia() else {
            // 当前无有效多媒体，停止播放
            log(prefix: .mediaPlayer, "Items is none")
            return nil
        }
        
        guard let indexPath = currentIndexPath else {
            // 当前无有效下标，返回首个播放顺序
            return getValidMediaIndexPaths().first
        }

        switch loopMode {
        case .single:
            // 单曲循环
            return currentIndexPath
            
        case .shuffle:
            // 随机循环
            return getValidMediaRandomIndexPath()
            
        case .album:
            // 歌单、专辑循环
            
            guard isExistsValidMedia() else {
                return nil
            }

            let list = getValidMediaIndexPaths(at: indexPath.section)
            let index = list.firstIndex(of: indexPath) ?? 0
            guard index > 0 else {
                return list.last // 当前是一个，返回歌单最后一个
            }
            return list[index - 1]
            
        case .order:
            // 顺序循环
            
            let list = getValidMediaIndexPaths()
            let index = list.firstIndex(of: indexPath) ?? 0
            guard index > 0 else {
                return list.last // 当前是一个，返回歌单最后一个
            }
            
            return list[index - 1]
            
        case .none:
            // 不循环
            
            let list = getValidMediaIndexPaths()
            let index = list.firstIndex(of: indexPath) ?? 0
            guard index > 0 else {
                return list.last // 当前是一个，返回歌单最后一个
            }
            return list[index - 1]
        }
    }
    
    
    /// Index是否有效（是否越界、是否有数据）
    func isValidIndexPath(_ indexPath: IndexPath) -> Bool {
        guard indexPath.section < items.count else {
            return false
        }
        guard indexPath.row < items[indexPath.section].mediaList.count else {
            return false
        }
        return true
    }
    
    ///  IndexPath 是否是当前二维列表的最后一个
    func isLastIndexPathInItems(_ indexPath: IndexPath) -> Bool {
        guard let indexPath = currentIndexPath else {
            return false
        }
        guard indexPath.section == items.count - 1 else {
            return false
        }
        guard indexPath.row == items[indexPath.section].mediaList.count - 1 else {
            return false
        }
        return true
    }
}

//MARK: - IndexPath 相关

public extension MediaPlayerControl {
    /// 获取基于当前索引的`下一个`索引，返回`none` =  需停止播放
    func getNextMediaIndexPath() -> IndexPath? {
        
        guard isExistsValidMedia() else {
            // 当前无有效多媒体，停止播放
            log(prefix: .mediaPlayer, "Items is none")
            return nil
        }
        
        guard let indexPath = currentIndexPath else {
            // 当前无有效下标，返回首个播放顺序
            return getValidMediaIndexPaths().first
        }

        switch loopMode {
        case .single:
            // 单曲循环
            return currentIndexPath
            
        case .shuffle:
            // 随机循环
            return getValidMediaRandomIndexPath()
            
        case .album:
            // 歌单、专辑循环
            
            guard isExistsValidMedia() else {
                return nil
            }

            let list = getValidMediaIndexPaths(at: indexPath.section)
            let index = list.firstIndex(of: indexPath) ?? 0
            guard index < list.count - 1 else {
                return list.first // 最后一个，返回歌单第一个
            }
            return list[index + 1]
            
        case .order:
            // 顺序循环
            
            let list = getValidMediaIndexPaths()
            let index = list.firstIndex(of: indexPath) ?? 0
            guard index < list.count - 1 else {
                return list.first // 最后一个，返回第一个
            }
            
            return list[index + 1]
            
        case .none:
            // 不循环
            
            let list = getValidMediaIndexPaths()
            let index = list.firstIndex(of: indexPath) ?? 0
            guard index < list.count - 1 else {
                return nil // 最后一个，不再继续播放
            }
            return list[index + 1]
        }
        
    }
    
    // 获取有效的
    func isExistsValidMedia() -> Bool {
        return items.contains(where: { $0.mediaList.contains(where: { $0.isValid }) })
    }
    
    /// 获取随机一个有效多媒体下标
    func getValidMediaRandomIndexPath() -> IndexPath? {
        let list = getValidMediaIndexPaths()
        guard list.count > 0 else {
            return nil
        }
        var randomGenerator = SystemRandomNumberGenerator()
        let randomInt = Int.random(in: 0..<list.count, using: &randomGenerator)
        let indexPath = list[randomInt]
        return indexPath
    }
    
    /// 获取有效多媒体的下标列表
    func getValidMediaIndexPaths() -> [IndexPath] {
        // 便利并返回有效的多媒体的indexPath
        let validIndexPaths = items.enumerated().map { getValidMediaIndexPaths(at: $0.offset) }
        let indexPaths = validIndexPaths.flatMap({ $0 })
        return indexPaths
    }
    
    
    /// 获取某`Section`有效多媒体的的下标列表
    func getValidMediaIndexPaths(at section: Int) -> [IndexPath] {
        guard items.count > section else {
            return []
        }
        let indexPaths = items[section].mediaList.enumerated().compactMap { element in
            // 有效则返回indexPath，否则返回nil
            return element.element.isValid ? IndexPath(row: element.offset, section: section) : nil
        }
        return indexPaths
    }
    
}

public extension IndexPath {
    var descriptionForPlayer: String {
        return "[\(section) - \(row)]"
    }
}
