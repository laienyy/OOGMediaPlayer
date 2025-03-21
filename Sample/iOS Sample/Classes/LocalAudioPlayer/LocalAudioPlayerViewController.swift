//
//  LocalAudioPlayerViewController.swift
//  MediaPlayerSample
//
//  Created by YiYuan on 2024/10/14.
//

import UIKit
import OOGMediaPlayer
import Combine


class LocalAudioPlayerViewController: UIViewController, AudioPlayerOwner {

    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var playingRateButton: UIButton!
    
    // 播放按钮
    @IBOutlet weak var playButton: UIButton!
    // 下一曲按钮
    @IBOutlet weak var forwardButton: UIButton!
    // 上一曲按钮
    @IBOutlet weak var backwardButton: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    // 下载进度条
    @IBOutlet weak var progressView: UIProgressView!
    // 使用缓存按钮
    @IBOutlet weak var enableCacheButton: UISwitch!
    
    // 播放器
    let playerProvider = OOGAudioPlayerProvider<AudioAlbumModel>()
    
//    var medias = [[item, itemB], [itemC, itemD, itemE], [item3_1, item3_2]]
    
    var playingTimer: Timer?
    
    var listViewController: MediaListViewController?
    
    
    var settings = OOGAudioPlayerSettings.loadScheme(.bgm, defaultSettings: nil)
    
    var cancelables = Set<AnyCancellable>()
    
    deinit {
        cancelables.forEach { $0.cancel() }
        cancelables.removeAll()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        playerManager.delegate = self
        
        playerProvider.delegate = self
        playingRateButton.addTarget(self, action: #selector(changePlayerRate), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(playOrPause), for: .touchUpInside)
        
        activityIndicator.layer.cornerRadius = 5
        activityIndicator.layer.masksToBounds = true
        
        enableCacheButton.addTarget(self, action: #selector(enableCacheSwitchValueChanged), for: .valueChanged)
        enableCacheButton.isOn = settings.isEnableCache
        
        Task {
            do {
                // 获取缓存
//                let models = [AudioAlbumModel].getListFromCache(.animation)
                let info = GetBGMListApiInfo(scheme: .dev, project: .oog200, type: .animation, language: "en")
                let models = try await playerProvider.getMusicFromServer(info, updateToUseCache: true)
                playerProvider.reloadData(models)
                playAudioIfDataSourceExists()
                
            } catch let error {
//                self.statusLabel.text = ""
                print("Get media list failed:", error.localizedDescription)
            }
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playingRateButton.layer.cornerRadius = playingRateButton.frame.height / 2
        playingRateButton.layer.masksToBounds = true
    }

    @objc func changePlayerRate() {
        guard playerProvider.isRateEnable else {
            playingRateButton.setTitle("1.0X", for: .normal)
            return
        }
        
        let currentRate = playerProvider.rate
        switch currentRate {
        case 1.0:
            playerProvider.rate = 1.5
            playingRateButton.setTitle("1.5X", for: .normal)
        case 1.5:
            playerProvider.rate = 2.0
            playingRateButton.setTitle("2.0X", for: .normal)
        case 2.0:
            playerProvider.rate = 2.5
            playingRateButton.setTitle("2.5X", for: .normal)
        case 2.5:
            playerProvider.rate = 3.0
            playingRateButton.setTitle("3.0X", for: .normal)
        case 3.0:
            playerProvider.rate = 1.0
            playingRateButton.setTitle("1.0X", for: .normal)
        default:
            break
        }
    }
    
    func updateCurrentTime() {
        let min = Int(playerProvider.currentTime) / 60
        let sec = Int(playerProvider.currentTime) % 60
        
        let durationMin = Int(playerProvider.duration) / 60
        let durationSec = Int(playerProvider.duration) % 60
        
        timeLabel.text = String(format: "%02d:%02d / %02d:%02d", min, sec, durationMin, durationSec)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        listViewController = nil
    }
    
    func startActivityIndicator(_ start: Bool) {
        if start {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
        } else {
            activityIndicator.isHidden = true
            activityIndicator.stopAnimating()
        }
        
    }
}

extension LocalAudioPlayerViewController {
    
    @objc func enableCacheSwitchValueChanged(_ sender: UISwitch) {
        settings.isEnableCache = sender.isOn
    }

    @IBAction func showMusicList(_ sender: Any) {
        
        let vc = MediaListViewController()
        vc.list = playerProvider.albumList
        vc.playerProvider = playerProvider
        vc.selectAction = { [weak self] vc, indexPath in
            self?.playerProvider.load(indexPath: indexPath)
        }
        listViewController = vc
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func playOrPause() {
        if playerProvider.playerStatus == .playing {
            playerProvider.pause()
        } else {
            playerProvider.play()
        }
    }
    
    @IBAction func forward(_ sender: Any) {
        playerProvider.playNext()
    }
    @IBAction func backward(_ sender: Any) {
        playerProvider.playPrevious()
    }
    
}


extension LocalAudioPlayerViewController: MediaPlayerControlDelegate {
    
    func mediaPlayerControl(_ control: MediaPlayerControl, willStopAt indexPath: IndexPath, error: any Error) {
        
    }
    
    func mediaPlayerControl(_ control: MediaPlayerControl, shouldPlay indexPath: IndexPath) -> IndexPath? {
        if let currentIndexPath = control.currentIndexPath,
           control.isLastIndexPathInItems(currentIndexPath),
           indexPath.section == 0,
           indexPath.row == 0 {
            
            // 最后一个播放完了
        }
        
        // 停止
        let audioItem = playerProvider.currentSong()
        // 取消下载
        audioItem?.cancelFileDownload()
        
        if let nextSong = playerProvider.getSong(at: indexPath) {
            
            nextSong.$downloadProgress.receive(on: DispatchQueue.main).sink { [weak self] status in
                guard let `self` = self else { return }
                switch status {
                case .normal, .downloaded:
                    self.progressView.isHidden = true
                    self.progressView.progress = 0
                case let .failed(error):
                    print("Download failed:", error)
                case let .downloading(progress):
                    self.progressView.isHidden = false
                    self.progressView.progress = Float(progress)
                @unknown default:
                    break
                }
            }.store(in: &cancelables)
        }
        
        // 即将播放的不变
        return indexPath
    }
    
    func mediaPlayerControl(_ control: MediaPlayerControl, playAt indexPath: IndexPath?, error: any Error) {
        
        if indexPath != nil, playerProvider.currentIndexPath != indexPath {
            return
        }
        
        guard let indexPath = indexPath else {
            statusLabel.text = "播放上一曲失败，错误：\(error.localizedDescription)"
            return
        }
        
        if let media = playerProvider.getSong(at: indexPath) {
            statusLabel.text = "播放\n\n`\(media.fileName)`,\n\n失败，错误：\(error.localizedDescription)"
        } else {
            statusLabel.text = "播放\n\n未知歌曲\n\n失败，未知错误"
        }
    }
    
    func mediaPlayerControl(_ control: MediaPlayerControl, at indexPath: IndexPath?, playBackwardError error: any Error) {
        
        if indexPath != nil, playerProvider.currentIndexPath != indexPath {
            return
        }
        
        guard let indexPath = indexPath else {
            return
        }
        
        if let media = playerProvider.getSong(at: indexPath) {
            statusLabel.text = "播放\n\n`\(media.fileName)`,\n\n失败，错误：\(error.localizedDescription)"
        } else {
            statusLabel.text = "播放\n\n未知歌曲\n\n失败，未知错误"
        }
    }
    
    func mediaPlayerControl(_ control: MediaPlayerControl, willPlay indexPath: IndexPath) {
        guard let media = playerProvider.getSong(at: indexPath) else {
            return
        }
        
        startActivityIndicator(true)
        
        statusLabel.text = "[\(indexPath.section) - \(indexPath.row)]\n\n正在加载\n\n\(media.fileName)"
        nameLabel.text = media.fileName
        timeLabel.text = "— / —"
        
        listViewController?.setCurrentIndexPath(indexPath)
    }
    
    func mediaPlayerControl(_ control: MediaPlayerControl, startPlaying indexPath: IndexPath) {
        
        
        guard let media = playerProvider.getSong(at: indexPath) else {
            return
        }
        
        startActivityIndicator(false)
        
//        print("Playing `\(media.name)`, at [\(indexPath.section), \(indexPath.row)]")
        statusLabel.text = "[\(indexPath.section) - \(indexPath.row)]\n\n正在播放\n\n\(media.fileName)"
    }
    
    func mediaPlayerControlStatusDidChanged(_ control: MediaPlayerControl) {
        let status = control.playerStatus
        if status == .playing {
            // 添加刷新当前时间的timer
            playingTimer = .scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] timer in
                self?.updateCurrentTime()
            })
            playButton.setImage(.init(systemName: "pause.fill"), for: .selected)
            
            if let indexPath = playerProvider.currentIndexPath, let media = playerProvider.currentItem() {
                statusLabel.text = "[\(indexPath.section) - \(indexPath.row)]\n\n正在播放\n\n\(media.fileName)"
            }
            
            playingRateButton.backgroundColor = playerProvider.isRateEnable ? .tintColor : .lightGray
            playingRateButton.isEnabled = playerProvider.isRateEnable
            
        } else {
            // 停止刷新当前时间的timer
            playingTimer?.invalidate()
            playingTimer = nil
            
            playButton.setImage(.init(systemName: "play.fill"), for: .normal)
            
            if let indexPath = playerProvider.currentIndexPath, let media = playerProvider.currentItem() {
                if status == .paused {
                    statusLabel.text = "[\(indexPath.section) - \(indexPath.row)]\n\n\(status.userInterfaceDisplay())\n\n\(media.fileName)"
                }
            }
        }
        
        playButton.isSelected = control.playerStatus == .playing
    }
}
