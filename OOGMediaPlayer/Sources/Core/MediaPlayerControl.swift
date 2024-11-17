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

extension Notification.Name {
    static let mediaPlayerControlDidChangedNextIndexPathForShuffleLoop = Notification.Name(rawValue: "com.oog.localAudioPlayerProvider.notification.didChangedNextIndexPathForShuffleLoop")
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



open class MediaPlayerControl: NSObject {
    
    // 播放历史
    public struct HistoryItem {
        public var media: any MediaPlayable
        public var indexPath: IndexPath
        public var time = Date()
    }
    
    public enum PlayDirection {
        // 指定的条目
        case specified
        // 下一个条目
        case next
        // 上一个条目
        case previous
    }
    
    public weak var delegate: MediaPlayerControlDelegate?
    
    public var isEnable: Bool = true
    
    /// 播放器状态
    public var playerStatus: PlayerStatus = .stoped
    /// 循环模式
    public var loopMode: LoopMode = .order
    
    /// 下一首多媒体的位置
    private var nextIndexPathForShuffleLoop: IndexPath?
    
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
    private var items: [any MediaAlbum] = .init()
    
    
    /**
     根据 Media 重置 `CurrentIndexPath`，
     
        - Parameters:
            - media: 目标
            - playFirstIfNotCatch: 未找到当前播放的时候是否自动播放
     */
    open func resetCurrentIndexBy(_ media: MediaPlayable) {
        currentIndexPath = indexPathOf(mediaID: media.resId)
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
        
        return media(at: indexPath)
    }
    
    open func getItems() -> [any MediaAlbum] {
        return items
    }
    
    /**
     *  刷新播放列表（不支持自动纠正`currentIndexPath`）
     *
     *  调用这个函数会重新定位 `currentIndexPath`
     */
    open func reloadData(_ items: [any MediaAlbum]) {
        // 删除历史记录
        history.removeAll()
        
        let playingMedia = currentItem()
        
        self.items = items
        
        
        if let _ = nextIndexPathForShuffleLoop {
            // 如果有预设，重设随机模式的下一曲index
            nextIndexPathForShuffleLoop = getValidMediaRandomIndexPath()
        }
        
        if let media = playingMedia {
            // 重新定位正在播放的歌曲的下标
            resetCurrentIndexBy(media)
        }
        
    }
    
    /// 刷新专辑（不支持自动纠正`currentIndexPath`）
    open func reload(section: Int, _ album: any MediaAlbum) {
        guard items.count > section else {
            return
        }
        
        if let next = nextIndexPathForShuffleLoop, next.section >= section {
            // 纠正随机播放下一首歌曲的位置
            if next.section == section {
                nextIndexPathForShuffleLoop = nil
            } else if next.section > section {
                nextIndexPathForShuffleLoop = getValidMediaRandomIndexPath()
            }
        }
        
        items[section] = album
    }
    
    /// 插入专辑（支持自动纠正`currentIndexPath`）
    open func insert(section: Int, _ album: any MediaAlbum) {
        guard items.count >= section else {
            return
        }
        
        if let current = currentIndexPath {
            // 纠正当前播放多媒体的位置
            if current.section > section {
                let new = IndexPath(row: current.row, section: current.section + 1)
                currentIndexPath = new
                log(prefix: .mediaPlayer, "Correct `CurrentIndexPath` from \(new) to \(new)")
            }
        }
        
        if let next = nextIndexPathForShuffleLoop, next.section >= section {
            // 纠正随机播放下一首歌曲的位置
            updateNextIndexPathForShuffleLoop(IndexPath(row: next.row, section: next.section + 1))
        }
        
        items.insert(album, at: section)
    }
    
    /// 移除专辑（支持自动纠正`currentIndexPath`）
    open func remove(section: Int) {
        guard items.count > section else {
            return
        }
        
        if let current = currentIndexPath {
            // 纠正当前播放多媒体的位置
            if current.section > section {
                let new = IndexPath(row: current.row, section: current.section - 1)
                currentIndexPath = new
                log(prefix: .mediaPlayer, "Correct `CurrentIndexPath` from \(current) to \(new)")
            }
        }
        
        if let next = nextIndexPathForShuffleLoop, next.section >= section {
            // 纠正随机播放下一首歌曲的位置
            if next.section == section {
                nextIndexPathForShuffleLoop = nil
                updateNextIndexPathForShuffleLoop(nil)
            } else if next.section > section {
                updateNextIndexPathForShuffleLoop(IndexPath(row: next.row, section: next.section - 1))
            }
        }
        
        items.remove(at: section)
    }
    
    /// 预设随机模式下的下一个播放条目位置（自己指定）
    open func presetNextIndexPathForShuffleLoop(_ indexPath: IndexPath) {
        updateNextIndexPathForShuffleLoop(indexPath)
    }
    
    /// 预设随机模式下的下一个播放条目位置（内部获取随机一个有效的条目）
    open func presetNextIndexPathForShuffleLoop() -> IndexPath? {
        updateNextIndexPathForShuffleLoop(getValidMediaRandomIndexPath())
        return nextIndexPathForShuffleLoop
    }
    
    /// 更新随机模式的下一个播放条目
    func updateNextIndexPathForShuffleLoop(_ indexPath: IndexPath?) {
        nextIndexPathForShuffleLoop = indexPath
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .mediaPlayerControlDidChangedNextIndexPathForShuffleLoop, object: self)
        }
    }
    
    /// 播放下一条
    open func playNext() {
        lastPlayDirection = .next
        guard let indexPath = getNextMediaIndexPath() else {
            log(prefix: .mediaPlayer, "Play next failed, not found invalid `indexPath`")
            playError(at: nil, error: OOGMediaPlayerError.MediaPlayerControlError.noInvalidItem)
            return
        }
        // 删除随机播放模式下的指定位置
        nextIndexPathForShuffleLoop = nil
        toPlay(indexPath: indexPath)
    }
    
    /// 播放上一条
    open func playPrevious() {
        lastPlayDirection = .previous
        guard let indexPath = getPreviousIndexPath() else {
            log(prefix: .mediaPlayer, "Play previous failed, not found invalid `indexPath`")
            playError(at: nil, error: OOGMediaPlayerError.MediaPlayerControlError.noInvalidItem)
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
    private func toPlay(indexPath: IndexPath) {
        
        guard isEnable else {
            log(prefix: .mediaPlayer, "Try to play failed, enable is false")
            playError(at: indexPath, error: OOGMediaPlayerError.MediaPlayerControlError.isNotEnable)
            return
        }
        
        log(prefix: .mediaPlayer, "Should play item at - (\(indexPath.section), \(indexPath.row))", media(at: indexPath).debugDescription)
        
        // 暂停当前播放
        if currentIndexPath != nil {
            stop()
        }
        
        let delegateResponseIndexPath = delegate?.mediaPlayerControl(self, shouldPlay: indexPath, current: currentIndexPath)
        
        // 如果 delegate == nil，直接使用 currentIndexPath，不能够直接使用 ?? 添加默认indexPath
        let next = delegate == nil ? indexPath : delegateResponseIndexPath
        
        guard let next = next else {
            log(prefix: .mediaPlayer, "Play next item failed, there is no `indexPath` specified")
            playError(at: nil, error: OOGMediaPlayerError.MediaPlayerControlError.noInvalidItem)
            return
        }
        currentIndexPath = next
        
        // 更新`indexPath` 可能由delegate返回一个新的
        delegate?.mediaPlayerControl(self, willPlay: next)
        
        Task {
            do {
                // 准备开始播放
                try await prepareToPlayItem(at: next)
                alreadyToPlay(next)
            } catch let error {
                log(prefix: .mediaPlayer, "Play next item failed, error: \(error)")
                playError(at: next, error: error)
            }
        }
        
    }
    
    /// 已经准备好播放，需要判断
    private func alreadyToPlay(_ indexPath: IndexPath) {

        let next = indexPath
        guard currentItem()?.resId == media(at: next)?.resId else {
            // 全局当前索引 != 本次流程需执行索引
            let msg = "Play next item failed, the `currentIndexPath` is changed, Should play: \(self.currentIndexPath?.descriptionForPlayer ?? "Nil"), Now: \(next.descriptionForPlayer)"
            log(prefix: .mediaPlayer, msg)
            return
        }
        
        log(prefix: .mediaPlayer, "Play item at \(next.descriptionForPlayer) - \(currentItem()?.fileName ?? "unknown") (ID:\(currentItem()?.resId ?? -1))")
        
        if let item = media(at: next) {
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
        DispatchQueue.main.async {
            self.delegate?.mediaPlayerControl(self, playAt: indexPath, error: error)
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

    func album(at section: Int) -> (any MediaAlbum)? {
        guard items.count > section else {
            return nil
        }
        return items[section]
    }
    
    func media(at indexPath: IndexPath) -> MediaPlayable? {
        guard isValidIndexPath(indexPath) else {
            log(prefix: .mediaPlayer, "IndexPath is out of range", indexPath, items.count)
            return nil
        }
        let media = items[indexPath.section].mediaList[indexPath.row]
        return media
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
    
    // 获取有效的
    func isExistsValidMedia() -> Bool {
        return items.contains(where: { $0.mediaList.contains(where: { $0.isValid }) })
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
    
    /// 获取歌曲在所有专辑中的首个位置（允许存在多个相同ID的多媒体）
    func indexPathOf(mediaID: Int) -> IndexPath? {
        for section in items.enumerated() {
            if let index = section.element.mediaList.firstIndex(where: { $0.resId == mediaID }) {
                return .init(row: index, section: section.offset)
            }
        }
        return nil
    }
    
    /// 获取歌曲在所有专辑中的所有位置（允许存在多个相同ID的多媒体）
    func indexPathListOf(mediaId: Int) -> [IndexPath] {
        var result = [IndexPath]()
        for section in items.enumerated() {
            if let index = section.element.mediaList.firstIndex(where: { $0.resId == mediaId }) {
                result.append(.init(row: index, section: section.offset))
            }
        }
        return result
    }
    
    /// 获取基于当前索引的前一个索引，返回`none` =  需停止播放
    func getPreviousIndexPath() -> IndexPath? {
        guard isExistsValidMedia() else {
            // 当前无有效多媒体，停止播放
            log(prefix: .mediaPlayer, "Not found valid item")
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
    /// 获取基于当前索引的`下一个`索引，返回`none` =  需停止播放
    func getNextMediaIndexPath() -> IndexPath? {
        
        guard isExistsValidMedia() else {
            // 当前无有效多媒体，停止播放
            log(prefix: .mediaPlayer, "Not found valid item")
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
            // 随机循环 （已有指定的播放位置则返回指定的位置）
            return nextIndexPathForShuffleLoop ?? getValidMediaRandomIndexPath()
            
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
