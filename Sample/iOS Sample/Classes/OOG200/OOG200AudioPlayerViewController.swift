//
//  OOG200AudioPlayerViewController.swift
//  iOS Sample
//
//  Created by YiYuan on 2024/10/23.
//

import Foundation
import UIKit
import OOGMediaPlayer
import MBProgressHUD
import AVFAudio

#if DEBUG
let scheme = ProjectScheme.distribution
//let scheme = ProjectScheme.preDistribution
//let scheme = ProjectScheme.test
//let scheme = ProjectScheme.dev
#else
let scheme = ProjectScheme.distribution
#endif


class OOG200AudioPlayerViewController: UIViewController, AudioPlayerOwner {
    
    typealias Album = AudioAlbumModel
    
    // 当前播放音乐信息部分
    @IBOutlet weak var playerWidgetView: AudioPlayerWidgetView!
    
    @IBOutlet weak var cacheEnableSwitch: UISwitch!
    @IBOutlet weak var mixOtherSwitch: UISwitch!
    @IBOutlet weak var iapSwitch: UISwitch!
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var backwardButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    // 随机播放按钮
    @IBOutlet weak var shufflePlayButton: UIButton!
    
    lazy var hud: MBProgressHUD = {
        let hud = MBProgressHUD(view: self.view)
        hud.frame = view.bounds
        hud.mode = .indeterminate
        hud.contentColor = .white
        hud.bezelView.blurEffectStyle = .dark
        hud.bezelView.style = .blur
        self.view.addSubview(hud)
        return hud
    }()
    
    
    var updateTimeTimer: Timer?
    var settings = OOGAudioPlayerSettings.loadScheme(.bgm, defaultSettings: nil)
    let playerProvider = OOGAudioPlayerProvider<Album>()
    
    deinit {
        print(OOG200AudioPlayerViewController.classNameStr, "deinit")
        do {
            try settings.save()
        } catch let error {
            print(error)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        iapSwitch.isOn = OOGAudioGlobalEnviroment.share.isIAPIActive
        syncSubsubviewsContentWithSettings()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 完全显示才重新设置delegate
        playerProvider.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        destoryTimer()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        iapSwitch.isOn = OOGAudioGlobalEnviroment.share.isIAPIActive
        
        playerWidgetView.soundSlider.setOog200SliderConfig()
        
        loadAudioWidgetView()
        startActivityIndicator(false)
        
        playerProvider.delegate = self
        syncSubsubviewsContentWithSettings()
        
        loadNotifications()
        loadPlayer()
    }
    
    func loadNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didStartPlay),
                                               name: .oogAudioPlayerDidStartPlayAudioNotification,
                                               object: playerProvider)
    }
    
    @objc func didStartPlay(_ notification: Notification) {
        
        /* * * * * * * 处理预下载 * * * * * */
        
        var preDownloadAudio: AudioModel?
        if playerProvider.loopMode == .shuffle {
            // 随机播放模式下特殊处理
            if let indexPath = playerProvider.presetNextIndexPathForShuffleLoop() {
                preDownloadAudio = playerProvider.media(at: indexPath) as? AudioModel
            }
        } else {
            // 其他播放模式
            if let indexPath = playerProvider.getNextMediaIndexPath() {
                preDownloadAudio = playerProvider.media(at: indexPath) as? AudioModel
            }
        }
        
        if let audio = preDownloadAudio {
            
            guard !audio.hasCache() else {
                print("下一首歌曲已有缓存 - 《 \(audio.fileName) 》")
                return
            }
            
            guard audio.isDownloading == false else {
                print("下一首歌曲已在下载中 - 《 \(audio.fileName) 》")
                return
            }
            
            Task {
                do {
                    print("开始预下载下一首歌曲 - 《 \(audio.fileName) 》")
                    try await audio.downloadFileData(timeoutInterval: 60)
                    print("预下载下一首歌曲完成 - 《 \(audio.fileName) 》")
                } catch let error {
                    print("预下载下一首歌曲出错 - 《 \(audio.fileName) 》，原因：", error)
                }
            }
        }
    }
    
    func loadPlayer() {
        Task {
            do {
                hud.show(animated: true)
                // 加载歌曲
                let info: GetBGMListApiInfo = .init(scheme: scheme, project: .oog200, type: .animation, language: "en")
                let models = try await playerProvider.getMusicFromServer(info, updateToUseCache: true)
                
                playerProvider.reloadData(models)
                
                // 刷新《我的喜欢》列表
                reloadFavoriteAlbum()
                // 根据设置，同步播放器
                updatePlayerWithSettings()
                // 设置淡进模式 （）
                playerProvider.playFadeMode = .once(8.0)
                
                // 根据设置恢复播放
                Task {
                    do {
                        // 根据设置恢复播放
                        try await playerProvider.resumePlay(by: settings, playAutomatically: true)
                    } catch let error {
                        // 根据设置会找到合适的 Audio 进行播放，播放下一曲
                        try await playerProvider.playNext()
                    }
                }
                
                hud.hide(animated: true, afterDelay: 0.5)
                
            } catch let error {
                statusLabel.text = "获取歌曲列表或加载音频失败，错误：\(error.localizedDescription)"
                hud.hide(animated: true, afterDelay: 0.5)
            }
        }
        
    }
    
    // 根据播放器当前状态，更新视图显示
    func syncSubsubviewsContentWithSettings() {
        
        settings = OOGAudioPlayerSettings.loadScheme(.bgm, defaultSettings: nil)
        
        if !settings.isEnablePlayer {
            playerProvider.pause()
        }
        // 更新播放器设置
        playerProvider.isUseCache = settings.isEnableCache
        // 更新播放器音量
        playerProvider.volume = settings.volumn

        // 更新是否使用缓存
        cacheEnableSwitch.isOn = settings.isEnableCache

        playerWidgetView.setEnable(settings.isEnablePlayer)
        playerWidgetView.setVolumn(settings.volumn, animated: false)
        playerWidgetView.setAudioName(playerProvider.currentSong()?.displayName ?? "无")
        
        
        // 更新随机播放模式按钮
        shufflePlayButton.isSelected = settings.loopMode == .shuffle
        // 更新播放按钮
        playButton.isSelected = playerProvider.playerStatus == .playing
        
        
        // 更新activity
        if let currentSong = playerProvider.currentSong() {
            switch currentSong.status {
            case .idle, .playing, .paused, .stoped, .error:
                startActivityIndicator(false)
            case .downloading, .prepareToPlay:
                startActivityIndicator(true)
            @unknown default:
                startActivityIndicator(false)
            }
        } else {
            startActivityIndicator(false)
        }
        
        // 更新状态栏
        switch playerProvider.playerStatus {
        case .stoped:
            statusLabel.text = "停止播放"
        case .prepareToPlay:
            statusLabel.text = "准备播放"
        case .playing, .paused, .finished, .error:
            let indexPath = playerProvider.currentIndexPath
            let media = playerProvider.currentSong()
            let statusStr = playerProvider.playerStatus.userInterfaceDisplay()
            statusLabel.text = "\(statusStr) - \(media?.fileName ?? "未知") \(indexPath?.descriptionForPlayer ?? "None")"
        @unknown default:
            break
        }
        
        // 更新播放时间
        updateTimeLable()
        if playerProvider.playerStatus == .playing {
            // 开始自动更新播放时间
            startUpdateTimeLabel()
        }
    }
    
    func startUpdateTimeLabel() {
        guard updateTimeTimer == nil else {
            return
        }
        
        updateTimeTimer = .scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] timer in
            guard let `self` = self else {
                timer.invalidate()
                return
            }
            self.updateTimeLable()
        })
    }
    
    func updateTimeLable() {
        guard let song = playerProvider.currentSong(), var duration = song.audioDuration else {
            timeLabel.text = "— / —"
            return
        }
        
        duration /= 1000
        let durationStr = String(format: "%02ld:%02ld", duration / 60, duration % 60)
        let currentTime = Int(playerProvider.currentTime)
        let currentTimeStr = String(format: "%02ld:%02ld", currentTime / 60, currentTime % 60)
        timeLabel.text = currentTimeStr + " / " + durationStr
    }
    
    func resetTimeLabel() {
        timeLabel.text = "— / —"
    }

    func destoryTimer() {
        updateTimeTimer?.invalidate()
        updateTimeTimer = nil
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
    
    func updateVolumnSliderValue() {
        playerWidgetView.setVolumn(playerProvider.volume, animated: true)
    }
    
    
    @IBAction func popViewController(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cacheSwitchValueChanged(_ sender: UISwitch) {
        settings.isEnableCache = sender.isOn
        try? settings.save()
        playerProvider.isUseCache = settings.isEnableCache
    }
    
    @IBAction func mixOtherAudioSwitchValueChanged(_ sender: UISwitch) {

        if sender.isOn {
            AVAudioSession.dukeOtherAudio()
        } else {
            AVAudioSession.mixOtherAudio()
        }
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        if sender.isSelected {
            playerProvider.pause()
        } else {
            playerProvider.play()
        }
    }
    
    @IBAction func forwardButtonPressed(_ sender: UIButton) {
        playerProvider.playNext()
    }
    
    @IBAction func backwardButtonPressed(_ sender: UIButton) {
        playerProvider.playPrevious()
    }
    
    @IBAction func shuffleButtonPressed(_ sender: UIButton) {
        let isShufflePlayMode = sender.isSelected
        if isShufflePlayMode {
            setPlayerLoop(mode: .order)
        } else {
            setPlayerLoop(mode: .shuffle)
        }
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func iapSwitchValueChanged(_ sender: UISwitch) {
        OOGAudioGlobalEnviroment.share.isIAPIActive = sender.isOn
    }
    
}


//MARK: - IBAction
extension OOG200AudioPlayerViewController {
    
}

//MARK: - App页面快速集成部分
extension OOG200AudioPlayerViewController {
    
    func loadAudioWidgetView() {
        playerWidgetView.setEnable(settings.isEnablePlayer)
        playerWidgetView.set(title: "APP音乐", musicTitle: "音乐")
        // 更新当前歌曲名称
        playerWidgetView.setAudioName(playerProvider.currentSong()?.displayName ?? "无")
        // 更新音量滑条
        playerWidgetView.setVolumn(settings.volumn, animated: false)
        
        playerWidgetView.enableSwitchValueChanged = { [weak self] view, enableSwitch in
            guard let `self` = self else { return }
            if enableSwitch.isOn {
                self.playerProvider.play()
                self.settings.isEnablePlayer = true
            } else {
                self.playerProvider.pause()
                self.settings.isEnablePlayer = false
            }
        }
        
        playerWidgetView.volumnSliderValueChanged = { [weak self] view, slider in
            self?.setVolumn(slider.value)
        }
        
        playerWidgetView.audioNameLabelTapped = { [weak self] view in
            self?.showAlbumList()
        }
    }
    
    func setVolumn(_ volumn: Float) {
        playerProvider.volume = volumn
        playerWidgetView.soundSlider.setValue(volumn, animated: true)
        settings.volumn = volumn
        try? settings.save()
    }
    
    func showAlbumList() {
        let vc = OOG200AudioListViewController(playerProvider, settings: settings, type: .planClassicAndChair)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension OOG200AudioPlayerViewController: MediaPlayerControlDelegate {
    
    func mediaPlayerControl(_ provider: MediaPlayerControl, playAt indexPath: IndexPath?, error: any Error) {
        
        if indexPath != nil, playerProvider.currentIndexPath != indexPath {
            return
        }
        
        startActivityIndicator(false)
        
        guard let indexPath = indexPath else {
            statusLabel.text = "播放上一曲失败，错误：\(error.localizedDescription)"
            return
        }
        
        if let media = playerProvider.getSong(at: indexPath) {
            statusLabel.text = "播放 - `\(media.fileName)`；失败，错误：\(error.localizedDescription)"
        } else {
            statusLabel.text = "播放 - 未知歌曲 - 失败，未知错误"
        }
    }
    
    func mediaPlayerControl(_ provider: MediaPlayerControl, shouldPlay indexPath: IndexPath, current: IndexPath?) -> IndexPath? {
        
        guard let media = playerProvider.getSong(at: indexPath) else {
            playerWidgetView.audioNameLabel.text = "无"
            return indexPath
        }
        playerWidgetView.setAudioName(media.displayName ?? "未命名")
        startActivityIndicator(true)
        
        return indexPath
    }
    
    func mediaPlayerControl(_ provider: MediaPlayerControl, willPlay indexPath: IndexPath) {
        guard let media = playerProvider.getSong(at: indexPath) else {
            return
        }
        statusLabel.text = "正在加载 - \(media.fileName) [\(indexPath.section) - \(indexPath.row)]"
    }
    
    func mediaPlayerControl(_ provider: MediaPlayerControl, startPlaying indexPath: IndexPath) {
        
//        updateVolumnSliderValue()
        startActivityIndicator(false)

        let name = playerProvider.getSong(at: indexPath)?.displayName ?? "无"
        playerWidgetView.setAudioName(name)
        
        guard let media = playerProvider.getSong(at: indexPath) else {
            return
        }
        
        //        print("Playing `\(media.name)`, at [\(indexPath.section), \(indexPath.row)]")
        statusLabel.text = "正在播放 - \(media.fileName) [\(indexPath.section) - \(indexPath.row)]"
        settings.currentAudioID = media.resId
    }
    
    func mediaPlayerControlStatusDidChanged(_ provider: MediaPlayerControl) {
        let status = provider.playerStatus
        
        playButton.isSelected = status == .playing
        
        if status == .playing {
            playButton.setImage(.init(systemName: "pause.fill"), for: .selected)
        } else {
            playButton.setImage(.init(systemName: "play.fill"), for: .normal)
            
            if let indexPath = playerProvider.currentIndexPath, let media = playerProvider.currentItem() {
                if status == .paused {
                    statusLabel.text = "\(status.userInterfaceDisplay()) - \(media.fileName) [\(indexPath.section) - \(indexPath.row)]"
                }
            }
        }
        
        
        switch status {
        case .playing:
            startUpdateTimeLabel()
            
        case .prepareToPlay, .error:
            resetTimeLabel()
            fallthrough
            
        case .paused, .stoped, .finished:
            destoryTimer()
        @unknown default:
            destoryTimer()
        }
        
    }
    
}

public extension AVAudioSession {
    static func dukeOtherAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback,
                                                            mode: AVAudioSession.Mode.default,
                                                            options: [.mixWithOthers, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Set duck other audio, error:", error)
        }
    }

    static func mixOtherAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback,
                                                            mode: AVAudioSession.Mode.default,
                                                            options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Set mix other audio, error:", error)
        }
    }
}
