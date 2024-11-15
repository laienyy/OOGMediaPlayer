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
        
        playerWidgetView.soundSlider.setOog200SliderConfig()
        
        loadAudioWidgetView()
        startActivityIndicator(false)
        
        playerProvider.delegate = self
        syncSubsubviewsContentWithSettings()
        
        loadPlayer()
    }
    
    func loadPlayer() {
        Task {
            do {
                hud.show(animated: true)
                // 加载歌曲
                let info: GetBGMListApiInfo = .init(scheme: scheme, project: .oog200, type: .animation, language: "en")
                let models = try await playerProvider.getMusicFromServer(info, updateToCache: true)
                
                playerProvider.reloadData(models)
                
                // 刷新《我的喜欢》列表
                reloadFavoriteAlbum()
                // 根据设置，同步播放器
                updatePlayerWithSettings()
                // 设置淡进模式 （）
                playerProvider.playFadeMode = .once(8.0)
                
                if !playerProvider.resumePlay(by: settings) {
                    // 根据设置未回复播放（大概率是未曾开始播放过），此处开始自动播放第一首
                    playerProvider.playNext()
                }
                
                hud.hide(animated: true, afterDelay: 0.5)
                
            } catch let error {
                statusLabel.text = "获取歌曲列表失败，错误：\(error.localizedDescription)"
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
    
}


//MARK: - IBAction
extension OOG200AudioPlayerViewController {
    
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
        let vc = OOG200AudioListViewController(playerProvider: playerProvider)
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
        
        guard let item = playerProvider.getSong(at: indexPath), !item.subscription else {
            let next = nextPlayableIndexPath(from: indexPath)
            return next
        }
        
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
