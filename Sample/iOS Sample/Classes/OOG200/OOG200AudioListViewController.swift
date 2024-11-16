//
//  OOG200AudioListViewController.swift
//  iOS Sample
//
//  Created by YiYuan on 2024/10/23.
//

import UIKit
import OOGMediaPlayer
import SDWebImage

private let favoriteAlbumID = -1

extension AudioModel {
    public override var description: String {
        let memeryAddress = Unmanaged.passUnretained(self).toOpaque()
        return "\(memeryAddress); #ID: \(resId), 《 \(musicName ?? "") 》, Subscription - \(subscription)"
    }
}

class OOG200AudioListViewController: UIViewController, AudioPlayerOwner {

    typealias Album = AudioAlbumModel
    
    var playerProvider: OOGAudioPlayerProvider<Album>
    var settings: OOGAudioPlayerSettings
    var type: BgmPlayType
    
    let tableView = UITableView(frame: UIScreen.main.bounds, style: .grouped)
    let tableHeaderView = BGMAlbumTableHeaderView()
    
    var foldAlbumList = Set<Int>()
    
    let lock = NSLock()
    
    deinit {
        // 移除OB，释放资源
        tableView.visibleCells.compactMap({ $0 as? BGMItemTableViewCell }).forEach({ $0.removeObservers() })
        try? settings.save()
    }
    
    init(_ playerProvider: OOGAudioPlayerProvider<Album>, settings: OOGAudioPlayerSettings, type: BgmPlayType) {
        self.playerProvider = playerProvider
        self.settings = settings
        self.type = type
        
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        playerProvider.playDesignatedLoopSongIfNeeds(settings: settings)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = playerProvider.currentIndexPath {
            tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        playerProvider.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "BGM"
        
//        tableView.registerHeaderFooterFromClass(AudioAlbumTableHeaderFooterView.self)
        tableView.registerHeaderFooterFromClass(BGMAlbumTableSectionHeaderView.self)
        tableView.registerHeaderFooterFromClass(BGMAlbumTableSectionFooterView.self)
        tableView.registerCellFromClass(BGMItemTableViewCell.self)
        tableView.estimatedSectionHeaderHeight = 70
        tableView.estimatedRowHeight = 70
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = #colorLiteral(red: 0.9594742656, green: 0.956212461, blue: 0.9530892968, alpha: 1)
        view.addSubview(tableView)
        
        tableHeaderView.shuffleSwitch.isOn = settings.loopMode == .shuffle
        tableHeaderView.shuffleSwitch.addTarget(self, action: #selector(shuffleSwitchValueChanged), for: .touchUpInside)
        let screenSize = UIScreen.main.bounds.size
        var size = tableHeaderView.systemLayoutSizeFitting(screenSize)
        size.width = screenSize.width
        tableHeaderView.frame = .init(origin: .zero, size: size)
        tableView.tableHeaderView = tableHeaderView
        
        loadPlayer()
    }
    
    func loadPlayer() {
        reloadFavoriteAlbum()
        if isViewLoaded {
            tableView.reloadData()
        }
    }
    
    @objc func shuffleSwitchValueChanged(_ sender: UISwitch) {
        if sender.isOn {
            setPlayerLoop(mode: .shuffle)
        } else {
            setPlayerLoop(mode: .order)
        }
    }
    
    func isFold(section: Int) -> Bool {
        let album = playerProvider.albumList[section]
        return foldAlbumList.contains(album.id)
    }
    
    func setFold(_ fold: Bool, album: any BGMAlbum) {
        if fold {
            foldAlbumList.insert(album.id)
        } else {
            foldAlbumList.remove(album.id)
        }
    }
    
    // album - 传入点击所属的album对象
    func favAlbumAddItem(_ audio: AudioModel, album: AudioAlbumModel) {
        
        settings.setFavorite(for: audio, true)
        
        var album = getFavoriteAlbum()
        if album == nil {
            // 当前数据源中不存在喜欢列表，新创建
            album = AudioAlbumModel()
            album?.playlistName = "我喜欢"
            album?.id = favoriteAlbumID
        }
        
        guard let favAlbum = album else {
            return
        }
        
        guard !favAlbum.mediaList.contains(where: { $0.resId == audio.resId }) else {
            return
        }
        
        
        /**
         *  取消喜欢，Favorite列表数量会受影响，播放器的当前播放的下标会出现偏差，导致播放下一曲时，当前歌曲的状态将无法正确更新
         *  最终纠正`currentIndex`在下方`self.playerProvider.resetCurrentIndexBy(song)`
         */
        let currentSong = self.playerProvider.currentSong()
        
        let insertIndex = favAlbum.mediaList.count
        favAlbum.mediaList.append(audio)
        
        tableView.performBatchUpdates { [weak self] in
            
            guard let `self` = self else { return }
            guard self.playerProvider.albumList.first?.isFavoriteAlbum ?? false else {
                // 插入喜欢section
                self.playerProvider.albumList.insert(favAlbum, at: 0)
                self.tableView.insertSections([0], with: .automatic)
                return
            }
            
            guard !self.isFold(section: 0) else {
                // 刷新Header
                self.tableView.reloadSections([0], with: .none)
                return
            }
            
            // 插入Row
            let indexPath = IndexPath(row: insertIndex, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .bottom)
            
        } completion: { finished in
            self.playerProvider.reloadData(self.playerProvider.albumList)
            self.tableView.reloadData()
            if let song = currentSong {
                if song.resId == audio.resId {
                    /**
                     在添加当前播放歌曲到《我喜欢》的位置之前，该歌曲在《我喜欢》是不存在的，所以正确的`currentIndexPath`只会是其他专辑中的那个位置
                     
                     （预期所有列表，最多只会存在两个相同resId的歌曲，即《我喜欢》和原所在的专辑）
                     */
                    let list = self.playerProvider.indexPathListOf(mediaId: song.resId)
                    if let indexPath = list.filter({ $0.section != 0 }).first {
                        self.playerProvider.currentIndexPath = indexPath
                    } else {
                        // 超出预期，根据默认规则重设 `currentIndexPath` 即可
                        self.playerProvider.resetCurrentIndexBy(song)
                    }
                } else {
                    // 添加到《我喜欢》的歌曲不是当前歌曲，不作特殊处理（预期状态，所有专辑的所有歌曲的resId是唯一的）
                    self.playerProvider.resetCurrentIndexBy(song)
                }
            }
        }
    }
    
    // album - 传入点击所属的album对象
    func favAlbumRemoveItem(_ audio: AudioModel, album: AudioAlbumModel) {
        
        settings.setFavorite(for: audio, false)
        
        guard let favAlbum = getFavoriteAlbum() else {
            return
        }
        
        guard let index = favAlbum.mediaList.firstIndex(where: { $0.resId == audio.resId }) else {
            return
        }

        /**
         *  取消喜欢，Favorite列表数量会受影响，播放器的当前播放的下标会出现偏差，导致播放下一曲时，当前歌曲的状态将无法正确更新
         *  最终纠正`currentIndex`在下方`self.playerProvider.resetCurrentIndexBy(song)`
         */
        let currentSong = self.playerProvider.currentSong()
        
        favAlbum.mediaList.remove(at: index)
        
        tableView.performBatchUpdates { [weak self] in
            guard let `self` = self else { return }
//            self.playerProvider.reloadData(self.albums)
            
            guard favAlbum.mediaList.count > 0 else {
                // 歌曲数量为0，删除section
                self.playerProvider.albumList.removeAll(where: { $0.isFavoriteAlbum })
                self.tableView.deleteSections([0], with: .automatic)
                return
            }
            
            guard !self.isFold(section: 0) else {
                // 被折叠，刷新整个section
                self.tableView.reloadSections([0], with: .automatic)
                return
            }
            
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.deleteRows(at: [indexPath], with: .bottom)
            
        } completion: { finished in
            self.playerProvider.albumList = self.playerProvider.albumList
            self.tableView.reloadData()
            if let song = currentSong {
                // 重设当前播放歌曲下标，从喜爱列表移除正在播放的歌曲，可能会导致currentIndexPath错误，并导致播放状态等出现未正常变化的问题
                self.playerProvider.resetCurrentIndexBy(song)
            }
        }
    }
    
}

extension OOG200AudioListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return playerProvider.albumList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let fold = isFold(section: section)
        let number = fold ? 0 : playerProvider.albumList[section].mediaList.count
        return number
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: BGMItemTableViewCell = .reuse(from: tableView)
        
        let album = playerProvider.albumList[indexPath.section]
        let song = album.mediaList[indexPath.row]
        
        let isFirst = indexPath.row == 0
        let isLast = indexPath.row + 1 == playerProvider.albumList[indexPath.section].mediaList.count
        
        cell.load(song)
        // 更新边角
        cell.updateCorner(isFirst: isFirst, isLast: isLast)
        // 是否喜欢
        cell.isFavorite = isFavorite(song: song)
        // 循环模式
        cell.isLoop = isLoop(song: song)
        // 订阅锁
        cell.isLock = song.subscription
        
        // 循环点击回调
        cell.loopAction = { [weak self] cell in
            guard let `self` = self, cell.model?.resId == song.resId else { return }
            
            let isLoop = cell.loopButton.isSelected
            if isLoop {
                // 取消循环
                self.setPlayerLoop(mode: .order)
            } else {
                // 单曲循环
                self.setPlayerSingleLoop(song: song)
            }
            self.tableHeaderView.shuffleSwitch.setOn(false, animated: true)
            // 刷新循环选中按钮状态
            self.tableView.reloadData()
        }
        
        // 喜欢点击回调
        cell.favoriteAction = { [weak self] cell in
            guard let `self` = self, cell.model?.resId == song.resId else { return }
            
            let isFavorite = self.settings.isFavorite(song)
            if album.isFavoriteAlbum {
                cell.isFavorite = !isFavorite
            }
            if !isFavorite == true {
                favAlbumAddItem(song, album: album)
            } else {
                favAlbumRemoveItem(song, album: album)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let song = playerProvider.getSong(at: indexPath)
        
        guard song?.subscription == false else {
            return
        }
        
        guard indexPath != playerProvider.currentIndexPath else {
            
            print("Current ID \(playerProvider.currentItem()?.resId ?? -10), selected ID \(playerProvider.getSong(at: indexPath)?.resId ?? -11)")
            
            if playerProvider.playerStatus == .playing {
                playerProvider.pause()
            } else {
                playerProvider.play()
            }
            
            return
        }
        
        playerProvider.play(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header: BGMAlbumTableSectionHeaderView = .reuse(from: tableView)
        
        let album = playerProvider.albumList[section]
        let isLoop = isLoop(album: album)
        
        let isFirst = section == 0
        let isLast = section + 1 == playerProvider.albumList.count
        let isFold = isFold(section: section)
        
        if album.isFavoriteAlbum {
            // 《喜欢的》专辑 icon
            header.specIconImage = UIImage(named: "bgm_my_fav")
        } else {
            // 其他专辑 icon
            header.specIconImage = nil
            if let str = album.phoneCoverImgUrl, let url = URL(string: str) {
                header.coverImageView.sd_setImage(with: url)
            } else {
                header.coverImageView.image = nil
            }
        }
        // 圆角处理
        header.updateCorner(isFirst: isFirst, isLast: isLast, isFold: isFold)
        
        header.isLoop = isLoop
        header.loopAction = { [weak self] header in
            guard let `self` = self else { return }
            
            let isLoop = header.isLoop
            if isLoop {
                self.setPlayerLoop(mode: .order)
            } else {
                self.setPlayerAlbumLoop(album: album)
            }
            self.tableHeaderView.shuffleSwitch.setOn(false, animated: true)
            // 刷新循环选中按钮状态
            self.tableView.reloadData()
        }
        
        header.isFold = isFold
        header.foldAction = { [weak self] header in
            guard let `self` = self else { return }
            
            let isFold = header.isFold
            if isFold {
                // 展开
                self.setFold(false, album: album)
            } else {
                // 收起
                self.setFold(true, album: album)
            }
            self.tableView.reloadData()
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let height = self.tableView(tableView, heightForFooterInSection: section)
        let footer: BGMAlbumTableSectionFooterView = .reuse(from: tableView)
        footer.isLast = section + 1 == playerProvider.albumList.count
        footer.frame = .init(x: 0, y: 0, width: tableView.frame.width, height: height)
        return footer
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let isLast = section + 1 == playerProvider.albumList.count
        
        if isLast {
            return isFold(section: section) ? 0.01 : 16.0
        } else {
            return 0.01
        }
    }
    
}

extension OOG200AudioListViewController: MediaPlayerControlDelegate {
    
    
    func mediaPlayerControl(_ control: MediaPlayerControl, shouldPlay indexPath: IndexPath, current: IndexPath?) -> IndexPath? {
        return indexPath
    }
    
    func mediaPlayerControl(_ control: MediaPlayerControl, willPlay indexPath: IndexPath) {

        let albums = playerProvider.albumList
        guard albums.count > indexPath.section, albums[indexPath.section].mediaList.count > indexPath.row else {
            return
        }
        
        settings.currentAudioID = albums[indexPath.section].mediaList[indexPath.row].resId
        try? settings.save()
    }
    
    func mediaPlayerControl(_ control: MediaPlayerControl, playAt indexPath: IndexPath?, error: any Error) {
        print("[ERR] Play \(indexPath?.descriptionForPlayer ?? "-") failed, response", error.localizedDescription)
    }
    
    func mediaPlayerControlStatusDidChanged(_ control: MediaPlayerControl) {
        let status = control.playerStatus
        print("Player status -", status.userInterfaceDisplay())
    }
    
}
