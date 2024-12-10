//
//  MediaPlayerControl.swift
//  BGMManagerSample
//
//  Created by YiYuan on 2024/10/10.
//

import UIKit
import AVFoundation

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
    public var nextIndexPathForShuffleLoop: IndexPath?
    
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
    fileprivate var items: [any MediaAlbum] = .init()
    
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
            // 重新定位正在播放的歌曲的位置
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
            log(prefix: .mediaPlayer, "Insert album [ \(album.albumNameForDebug) ] at section [\(section)] error, section is out range, count: \(items.count)")
            return
        }
        
        if let current = currentIndexPath, current.section >= section {
            // 添加的 seciton 在 currentSection 前面，需要将 currentIndex.section 向后偏移进行纠正
            let new = IndexPath(row: current.row, section: current.section + 1)
            log(prefix: .mediaPlayer, "Correct `CurrentIndexPath` from \(current) to \(new)")
            currentIndexPath = new
        }
        
        if let next = nextIndexPathForShuffleLoop {
            if section <= next.section {
                // 添加的 seciton 在 `nextIndexPathForShuffleLoop` 前面，需要将其后偏移进行纠正
                updateNextIndexPathForShuffleLoop(IndexPath(row: next.row, section: next.section + 1))
            }
        }
        
        items.insert(album, at: section)
        log(prefix: .mediaPlayer, "Insert album [ \(album.albumNameForDebug) ] at \(section)")
    }
    
    /// 移除专辑
    open func remove(section: Int) {
        guard items.count > section else {
            log(prefix: .mediaPlayer, "Remove album at section [\(section)] error, section is out range, count: \(items.count)")
            return
        }
        
        if let current = currentIndexPath, current.section > section {
            // 移除的专辑在当前播放歌曲的前面，播放歌曲的位置向前偏移 1 section
            let new = IndexPath(row: current.row, section: current.section - 1)
            log(prefix: .mediaPlayer, "Correct `CurrentIndexPath` from \(current) to \(new)")
            currentIndexPath = new
        }
        
        if let next = nextIndexPathForShuffleLoop {
            // 添加的 seciton 在 `nextIndexPathForShuffleLoop` 前面，需要进行纠正
            if next.section == section {
                // 删除并重新生成
                nextIndexPathForShuffleLoop = nil
                updateNextIndexPathForShuffleLoop(nil)
            } else if section < next.section  {
                // 插入在了前方，需要向后偏移进行纠正
                updateNextIndexPathForShuffleLoop(IndexPath(row: next.row, section: next.section - 1))
            }
        }
        
        items.remove(at: section)
        log(prefix: .mediaPlayer, "Remove album of section [ \(section) ]")
    }
    
    
    /**
     根据 Media 重置 `CurrentIndexPath`，
     
        - Parameters:
            - media: 目标
            - playFirstIfNotCatch: 未找到当前播放的时候是否自动播放
     */
    open func resetCurrentIndexBy(_ media: MediaPlayable) {
        currentIndexPath = indexPathOf(mediaID: media.resId)
    }
    
    open func resetCurrentIndexBy(_ mediaId: Int) {
        currentIndexPath = indexPathOf(mediaID: mediaId)
    }
    
    /// 获取上一条数据
    open  func getHistoryLastItem() -> MediaPlayable? {
        return history.last?.media
    }
    
    /// 获取当前播放音频
    open func currentItem() -> MediaPlayable? {
        return currentIndexPath == nil ? nil : media(at: currentIndexPath!)
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
        Task {
            try await playNext()
        }
    }
    open func playNext() async throws {
        lastPlayDirection = .next
        guard let indexPath = getNextMediaIndexPath() else {
            log(prefix: .mediaPlayer, "Play next failed, not found invalid `indexPath`")
            await playError(at: nil, error: OOGMediaPlayerError.MediaPlayerControlError.noInvalidItem)
            return
        }
        try await loadMedia(indexPath: indexPath, playDirection: lastPlayDirection)
    }
    
    /// 播放上一条
    open func playPrevious() {
        Task { try await playPrevious() }
    }
    open func playPrevious() async throws {
        lastPlayDirection = .previous
        guard let indexPath = getPreviousIndexPath() else {
            log(prefix: .mediaPlayer, "Play previous failed, not found invalid `indexPath`")
            await playError(at: nil, error: OOGMediaPlayerError.MediaPlayerControlError.noInvalidItem)
            return
        }
        try await loadMedia(indexPath: indexPath, playDirection: .previous)
    }
    
    open func load(indexPath: IndexPath, autoPlay: Bool = true) {
        Task {
            try await load(indexPath: indexPath, autoPlay: autoPlay)
        }
    }
    
    /// 播放指定索引 （不受`loopModel`影响）
    open func load(indexPath: IndexPath, autoPlay: Bool) async throws {
        lastPlayDirection = .specified
        try await loadMedia(indexPath: indexPath, playAutomaticly: autoPlay, playDirection: lastPlayDirection)
    }
    
    /// 根据索引播放
    open func loadMedia(indexPath next: IndexPath, playAutomaticly: Bool = true, playDirection: PlayDirection) async throws {
        
        lastPlayDirection = playDirection
        
        // 删除随机播放模式下的指定位置
        nextIndexPathForShuffleLoop = nil
        
        guard isEnable else {
            log(prefix: .mediaPlayer, "Try to load failed, `enable` is false")
            await playError(at: next, error: OOGMediaPlayerError.MediaPlayerControlError.isNotEnable)
            throw OOGMediaPlayerError.MediaPlayerControlError.isNotEnable
        }
        
        log(prefix: .mediaPlayer, "Should load item at - (\(next.section), \(next.row))", media(at: next).debugDescription)
        
        // 暂停当前播放
        if loopMode != .single,
           let indexPathNow = currentIndexPath,
           let audio = media(at: indexPathNow),
           audio.resId == media(at: next)?.resId {
            /**
             *  音乐是同一首，不进行其他处理，将新的indexPath设置为`currentIndex`
             *
             *  正常情况此处不应该有重复的`Media`出现，需要 play/pause 切换，在外部自行判断，此处只为避免重复加载一首歌，而出现超出预期的情况
             */
            log(prefix: .mediaPlayer, "Try load same one, ignore load this item at - (\(next.section), \(next.row))", media(at: next).debugDescription)
            currentIndexPath = next
            return
        } else {
            await stop()
        }

        
        let delegateResponseIndexPath = await delegate?.mediaPlayerControl(self, shouldPlay: next, current: currentIndexPath)

        // 如果 delegate == nil，直接使用 currentIndexPath，不能够直接使用 ?? 添加默认indexPath
        let next = delegate == nil ? next : delegateResponseIndexPath
        currentIndexPath = next
        
        guard let next = next else {
            log(prefix: .mediaPlayer, "Load next item failed, there is no `indexPath` specified")
            await playError(at: nil, error: OOGMediaPlayerError.MediaPlayerControlError.noInvalidItem)
            throw OOGMediaPlayerError.MediaPlayerControlError.noInvalidItem
        }

        do {
            // 准备开始播放
            try await prepareToPlayItem(at: next)
            
            // 自动开始播放
            await MainActor.run {
                
                alreadyToPlay(next)
                
                /**
                 * playerStatus != .prepareToPlay
                 *     说明：
                 *      1. 在等待`prepareToPlayItem`的时候，外部有其他操作
                 *      2. 或者在等待加载资源的过程中取消了播放状态
                 *
                 *      所以状态不是`prepareToPlay`时，打断自动播放处理流程
                 */
                if playAutomaticly, playerStatus == .prepareToPlay {
                    // 更新`indexPath` 可能由delegate返回一个新的
                    delegate?.mediaPlayerControl(self, willPlay: next)
                    play()
                } else {
                    pause()
                }
            }
            
        } catch let error {
            log(prefix: .mediaPlayer, "Load next item failed, error: \n\(error)")
            await playError(at: next, error: error)
            throw error
        }
        
    }
    
    /// 已经准备好播放，返回释放有效
    @MainActor
    open func alreadyToPlay(_ indexPath: IndexPath) {

        let next = indexPath
        log(prefix: .mediaPlayer, "Has already to play item at \(next.descriptionForPlayer) - \(currentItem()?.fileName ?? "unknown") (ID:\(currentItem()?.resId ?? -1))")
        
        if let item = media(at: next) {
            history.append(.init(media: item, indexPath: next))
        }
        
        var userInfo = ["indexPath" : indexPath] as [String : Any]
        userInfo["album"] = self.album(at: indexPath.section)
        userInfo["audio"] = self.media(at: indexPath)
        
        NotificationCenter.default.post(name: .mediaPlayerControlAlreadyToPlayAudio, object: self, userInfo: userInfo)
    }
    
    /// 准备播放
    @MainActor
    open func prepareToPlayItem(at indexPath: IndexPath) async throws {
        setStatus(.prepareToPlay)
    }
    
    @MainActor
    open func play() {
        setStatus(.playing)
    }
    
    @MainActor
    open func pause() {
        setStatus(.paused)
    }
    
    @MainActor
    open func stop() {
        log(prefix: .mediaPlayer, "Stop current play")
        setStatus(.stoped)
    }

    // 负责处理加载或播放多媒体的过程中的错误，并更新播放器状态
    @MainActor
    func playError(at indexPath: IndexPath?, error: any Error) {
        if indexPath != nil, indexPath == currentIndexPath {
            setStatus(.error)
        }
        self.delegate?.mediaPlayerControl(self, playAt: indexPath, error: error)
    }
 
    // 负责更新播放器状态以及`delegate`
    @MainActor
    func setStatus(_ status: PlayerStatus) {
        self.playerStatus = status
        self.delegate?.mediaPlayerControlStatusDidChanged(self)
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
    
    // 获取有效的
    func isExistsValidMedia() -> Bool {
        return items.contains(where: { $0.mediaList.contains(where: { $0.isValid }) })
    }
    

}
