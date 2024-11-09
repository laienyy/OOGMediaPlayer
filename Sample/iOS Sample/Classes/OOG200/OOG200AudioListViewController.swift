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

class OOG200AudioListViewController: UIViewController, AudioPlayerOwner {

    typealias Album = AudioAlbumModel
    
    var playerProvider: OOGAudioPlayerProvider<Album>
    
    lazy var favAlbum: AudioAlbumModel = {
        var album = AudioAlbumModel()
        album.playlistName = "我最喜欢的"
        album.id = favoriteAlbumID
        return album
    }()
    
    var settings = OOGAudioPlayerSettings.loadScheme(.bgm)
    
    let tableView = UITableView(frame: UIScreen.main.bounds, style: .grouped)
    let tableHeaderView = BGMAlbumTableHeaderView()
    
    var foldAlbumList = Set<Int>()
    
    let lock = NSLock()
    
    
    init(playerProvider: OOGAudioPlayerProvider<Album>) {
        self.playerProvider = playerProvider
        
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        playerProvider.playDesignatedLoopSongIfNeeds(settings: settings)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
//        if albums.count > 0 {
//            self.albums = [albums[0]]
//        }

        playerProvider.delegate = self
        
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
        tableHeaderView.titleLabel.text = "全部随机播放"
        tableHeaderView.shuffleSwitch.addTarget(self, action: #selector(shuffleSwitchValueChanged), for: .touchUpInside)
        let screenSize = UIScreen.main.bounds.size
        var size = tableHeaderView.systemLayoutSizeFitting(screenSize)
        size.width = screenSize.width
        tableHeaderView.frame = .init(origin: .zero, size: size)
        tableView.tableHeaderView = tableHeaderView
        
        loadFavoriteAlbum()
    }
    
    func loadFavoriteAlbum() {
    
        if let favAlbum = playerProvider.albumList.first(where: { $0.id == favoriteAlbumID }) {
            self.favAlbum = favAlbum
        }
        
        let songs = playerProvider.albumList.flatMap({ $0.mediaList })
        let favSongs: [AudioModel] =  settings.selectFavoriteSongs(by: songs)

        guard favSongs.count > 0 else {
            return
        }
        
        favAlbum.mediaList = favSongs
        
        if let index = playerProvider.albumList.firstIndex(where: { $0.id == favoriteAlbumID }) {
            playerProvider.albumList[index] = favAlbum
        } else {
            playerProvider.albumList.insert(favAlbum, at: 0)
        }
        
        guard isViewLoaded else {
            return
        }
    
        tableView.reloadData()
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
    func favAlbumAddItem(_ item: AudioModel, album: AudioAlbumModel) {
        
        settings.setFavorite(for: item, true)
        
        guard !favAlbum.mediaList.contains(where: { $0.id == item.id }) else {
            return
        }
        
        
        /**
         *  取消喜欢，Favorite列表数量会受影响，播放器的当前播放的下标会出现偏差，导致播放下一曲时，当前歌曲的状态将无法正确更新
         *  最终纠正`currentIndex`在下方`self.playerProvider.resetCurrentIndexBy(song)`
         */
        let currentSong = self.playerProvider.currentSong()
        
        let insertIndex = self.favAlbum.mediaList.count
        favAlbum.mediaList.append(item)
        
        tableView.performBatchUpdates { [weak self] in
            
            guard let `self` = self else { return }
            // 添加到喜欢列表
            
//            self.playerProvider.reloadData(albums)
            
            guard self.playerProvider.albumList.first?.id == favoriteAlbumID else {
                // 插入喜欢section
                self.playerProvider.albumList.insert(favAlbum, at: 0)
                print("[TableView] Insert section -", self.playerProvider.albumList.count)
                self.tableView.insertSections([0], with: .top)
                return
            }
            
            guard !self.isFold(section: 0) else {
                // 刷新Header
                print("[TableView] Reload section -", self.playerProvider.albumList.count)
                self.tableView.reloadSections([0], with: .none)
                return
            }
            
            let indexPath = IndexPath(row: insertIndex, section: 0)
            print("[TableView] Insert row -", insertIndex, 0)
            self.tableView.insertRows(at: [indexPath], with: .bottom)
            
        } completion: { finished in
            self.playerProvider.albumList = self.playerProvider.albumList
            self.tableView.reloadData()
            if let song = currentSong {
                // 重设当前播放歌曲下标，从喜爱列表移除正在播放的歌曲，可能会导致currentIndexPath错误，并导致播放状态等出现未正常变化的问题
                self.playerProvider.resetCurrentIndexBy(song, playFirstIfNotCatch: false)
            }
        }
    }
    
    // album - 传入点击所属的album对象
    func favAlbumRemoveItem(_ item: AudioModel, album: AudioAlbumModel) {
        
        settings.setFavorite(for: item, false)
        
        guard let index = favAlbum.mediaList.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        /**
         *  取消喜欢，Favorite列表数量会受影响，播放器的当前播放的下标会出现偏差，导致播放下一曲时，当前歌曲的状态将无法正确更新
         *  最终纠正`currentIndex`在下方`self.playerProvider.resetCurrentIndexBy(song)`
         */
        let currentSong = self.playerProvider.currentSong()
        
        self.favAlbum.mediaList.remove(at: index)
        
        tableView.performBatchUpdates { [weak self] in
            guard let `self` = self else { return }
//            self.playerProvider.reloadData(self.albums)
            
            guard favAlbum.mediaList.count > 0 else {
                // 歌曲数量为0，删除section
                self.playerProvider.albumList.removeAll(where: { $0.id == self.favAlbum.id })
//                print("[TableView] Delete section -", self.playerProvider.albumList.count)
                self.tableView.deleteSections([0], with: .automatic)
                return
            }
            
            guard !self.isFold(section: 0) else {
                // 被折叠，刷新整个section
//                print("[TableView] Reload section -", self.playerProvider.albumList.count)
                self.tableView.reloadSections([0], with: .automatic)
                return
            }
            
            let indexPath = IndexPath(row: index, section: 0)
//            print("[TableView] Delete row -", index, 0)
            self.tableView.deleteRows(at: [indexPath], with: .bottom)
            
        } completion: { finished in
            self.playerProvider.albumList = self.playerProvider.albumList
            self.tableView.reloadData()
            if let song = currentSong {
                // 重设当前播放歌曲下标，从喜爱列表移除正在播放的歌曲，可能会导致currentIndexPath错误，并导致播放状态等出现未正常变化的问题
                self.playerProvider.resetCurrentIndexBy(song, playFirstIfNotCatch: true)
            }
        }
    }
    
}

extension OOG200AudioListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
//        print("[TableView] Album count:", playerProvider.albumList.count)
        return playerProvider.albumList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let fold = isFold(section: section)
        let number = fold ? 0 : playerProvider.albumList[section].mediaList.count
//        print("[TableView] Section \(section) count:", number)
        return number
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: BGMItemTableViewCell = .reuse(from: tableView)
        
        let album = playerProvider.albumList[indexPath.section]
        let song = album.mediaList[indexPath.row]
        
        let isFirst = indexPath.row == 0
        let isLast = indexPath.row + 1 == playerProvider.albumList[indexPath.section].mediaList.count
        
        cell.load(song)
        cell.updateCorner(isFirst: isFirst, isLast: isLast)
        cell.isFavorite = isFavorite(song: song)
        cell.isLoop = isLoop(song: song)
        cell.isLock = song.subscription
        cell.loopAction = { [weak self] cell in
            guard let `self` = self, cell.model?.id == song.id else { return }
            
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
        cell.favoriteAction = { [weak self] cell in
            guard let `self` = self, cell.model?.id == song.id else { return }
            
            let isFavorite = self.settings.isFavorite(song)
            if album.id != favoriteAlbumID {
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
        
        guard indexPath != playerProvider.currentIndexPath else {
            
//            print("Current ID \(playerProvider.currentItem()?.id ?? -10), selected ID \(playerProvider.getSong(at: indexPath)?.id ?? -11)")
            
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
        
        if album.id == favoriteAlbumID {
            header.specIconImage = UIImage(named: "bgm_my_fav")
        } else {
            header.specIconImage = nil
            if let str = album.phoneCoverImgUrl, let url = URL(string: str) {
                header.coverImageView.sd_setImage(with: url)
            } else {
                header.coverImageView.image = nil
            }
        }
        

        header.titleLabel.text = album.name
        header.subtitleLabel.text = "\(album.mediaList.count) 歌曲"
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

extension OOG200AudioListViewController: MediaPlayerProviderDelegate {
    
    
    func mediaPlayerControl(_ provider: MediaPlayerControl, shouldPlay indexPath: IndexPath, current: IndexPath?) -> IndexPath? {
        
        if let current = current,
           let cell = tableView.cellForRow(at: current) as? AudioTableViewCell {
            // 即将播放其他曲目时，将正在播放的 cell 置为当前未播放
            cell.setIsCurrentPlay(false)
        }
        return indexPath
    }
    
    func mediaPlayerControl(_ provider: MediaPlayerControl, willPlay indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? AudioTableViewCell {
            // 将正在 cell 置为正在播放
            cell.setIsCurrentPlay(true)
        }
        let albums = playerProvider.albumList
        guard albums.count > indexPath.section, albums[indexPath.section].mediaList.count > indexPath.row else {
            return
        }
        
        settings.currentAudioID = albums[indexPath.section].mediaList[indexPath.row].id
        try? settings.save()
    }
    
    func mediaPlayerControl(_ provider: MediaPlayerControl, playAt indexPath: IndexPath?, error: any Error) {
        print("[ERR] Play \(indexPath?.descriptionForPlayer ?? "-") failed, response", error.localizedDescription)
    }
    
    func mediaPlayerControlStatusDidChanged(_ provider: MediaPlayerControl) {
        let status = provider.playerStatus
        print("Player status -", status.userInterfaceDisplay())
    }
    
}
