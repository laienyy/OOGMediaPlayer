//
//  AudioPlayerWidgetView.swift
//  iOS Sample
//
//  Created by YiYuan on 2024/10/29.
//

import UIKit
import SnapKit
import OOGMediaPlayer

class AudioPlayerWidgetView: UIView {
    
    //MARK: - UI
    
    public let contentView = UIView()
    
    public let topTitleLabel = UILabel()
    public let enableSwitch = UISwitch()
    
    public let audioImageView = UIImageView()
    public let audioTitleLabel = UILabel()
    public let audioNameLabel = UILabel()
    public let rightArrowImageView = UIImageView(image: UIImage(named: "icon_setting_arrowRight"))
    
    public let grayLine = UIView()
    
    public let soundSlider = OOGSlider()
    public let soundMinimumButton = UIButton(type: .custom)
    public let soundMaximumButton = UIButton(type: .custom)
    
    /// 内容外边距
    public var contentMarginInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16) {
        didSet { reloadSubviewsPosition() }
    }
    /// 内容内边距
    public var paddingInsets: UIEdgeInsets = .zero  {
        didSet { reloadSubviewsPosition() }
    }
    
    //MARK: - Events
    
    // 播放器开关
    public var enableSwitchValueChanged: ((AudioPlayerWidgetView, UISwitch) -> Void)?
    // 音量变化
    public var volumnSliderValueChanged: ((AudioPlayerWidgetView, OOGSlider) -> Void)?
    // 音频名称被点击
    public var audioNameLabelTapped: ((_ view: AudioPlayerWidgetView) -> Void)?

    
    deinit {
        print("AudioPlayerWidgetView deinit")
    }
    
    init() {
        super.init(frame: .zero)
        loadSubviews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadSubviews()
    }
}

extension AudioPlayerWidgetView {
    public func setEnable(_ isEnable: Bool) {
        enableSwitch.isOn = isEnable
    }
    
    public func set(title: String, musicTitle: String) {
        topTitleLabel.text = title
        audioTitleLabel.text = musicTitle
    }
    
    public func setImage(minimum: UIImage, maximum: UIImage, for state: UIControl.State) {
        soundMinimumButton.setImage(minimum, for: state)
        soundMaximumButton.setImage(maximum, for: state)
    }
    
    public func setAudioName(_ name: String) {
        audioNameLabel.text = name
    }
    
    public func setVolumn(_ volumn: Float, animated: Bool) {
        soundSlider.setValue(volumn, animated: animated)
    }
}

extension AudioPlayerWidgetView {
    @objc func enableSwitchValueDidChanged(_ sender: UISwitch) {
        enableSwitchValueChanged?(self, sender)
    }
    
    @objc func soundMinimumButtonPressed(_ sender: Any) {
        soundSlider.setValue(0, animated: true)
        soundSlider.sendActions(for: .valueChanged)
    }
    
    @objc func soundMaximumButtonPressed(_ sender: Any) {
        soundSlider.setValue(1, animated: true)
        soundSlider.sendActions(for: .valueChanged)
    }
    
    @objc func volumnSliderValueDidChanged(_ sender: OOGSlider) {
        volumnSliderValueChanged?(self, sender)
    }
    
    @objc func nameLabelDidPressed(_ sender: UITapGestureRecognizer) {
        audioNameLabelTapped?(self)
    }
}


extension AudioPlayerWidgetView {
    
    func loadSubviews() {

        // 避免重复加载
        guard contentView.superview == nil else {
            return
        }
        
        layer.cornerRadius = 4
        layer.masksToBounds = true
        
        topTitleLabel.text = "APP音乐"
        enableSwitch.onTintColor = .black
        enableSwitch.isEnabled = true
        audioImageView.image = UIImage(named: "AppIcon40")
        audioImageView.layer.cornerRadius = 4
        audioImageView.layer.masksToBounds = true
        audioTitleLabel.text = "音乐"
        audioNameLabel.text = "Some music"
        audioNameLabel.textColor = #colorLiteral(red: 0.6367008686, green: 0.6002740264, blue: 0.5924039483, alpha: 1)
        audioNameLabel.textAlignment = .right
        
        grayLine.backgroundColor = #colorLiteral(red: 0.9593991637, green: 0.9593990445, blue: 0.9593991637, alpha: 1)
        
        soundMinimumButton.tintColor = #colorLiteral(red: 0.5406724811, green: 0.5406724811, blue: 0.5406724811, alpha: 1)
        soundMinimumButton.setImage(UIImage(named: "ic_volume_close"), for: .normal)
        soundMaximumButton.tintColor = #colorLiteral(red: 0.5406724811, green: 0.5406724811, blue: 0.5406724811, alpha: 1)
        soundMaximumButton.setImage(UIImage(named: "ic_volume_max"), for: .normal)
        
        soundSlider.tintColor = #colorLiteral(red: 0.2341707945, green: 0.5062331557, blue: 0.3894308805, alpha: 1)
        
        
        // 事件
        enableSwitch.addTarget(self, action: #selector(enableSwitchValueDidChanged), for: .valueChanged)
        soundSlider.addTarget(self, action: #selector(volumnSliderValueDidChanged), for: .valueChanged)
        
        soundMinimumButton.addTarget(self, action: #selector(soundMinimumButtonPressed), for: .touchUpInside)
        soundMaximumButton.addTarget(self, action: #selector(soundMaximumButtonPressed), for: .touchUpInside)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(nameLabelDidPressed))
        audioNameLabel.isUserInteractionEnabled = true
        audioNameLabel.addGestureRecognizer(tap)
        
        
        addSubview(contentView)
        contentView.addSubview(topTitleLabel)
        contentView.addSubview(enableSwitch)
        contentView.addSubview(audioImageView)
        contentView.addSubview(audioTitleLabel)
        contentView.addSubview(audioNameLabel)
        contentView.addSubview(rightArrowImageView)
        
        contentView.addSubview(grayLine)
        
        contentView.addSubview(soundSlider)
        contentView.addSubview(soundMinimumButton)
        contentView.addSubview(soundMaximumButton)
        
        reloadSubviewsPosition()
    }
    
    func reloadSubviewsPosition() {
        
        guard contentView.superview != nil else { return }
        
        contentView.snp.remakeConstraints { make in
            let insets = contentMarginInsets
            make.leading.equalToSuperview().offset(insets.left)
            make.trailing.equalToSuperview().inset(insets.right)
            make.top.equalToSuperview().offset(insets.top)
            make.bottom.equalToSuperview().inset(insets.bottom)
        }
        
        let paddingLeft = paddingInsets.left
        let paddingRight = paddingInsets.right
        
        topTitleLabel.snp.remakeConstraints { make in
            // l 16, r 16, t 24
            make.leading.equalToSuperview().offset(paddingLeft)
            make.trailing.equalToSuperview().inset(paddingRight)
            make.top.equalToSuperview().offset(24)
        }
        enableSwitch.snp.remakeConstraints { make in
//            make.leading.equalTo(topTitleLabel.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(paddingRight)
            make.centerY.equalTo(topTitleLabel)
        }
        audioImageView.setContentCompressionResistancePriority(.init(750), for: .horizontal)
        audioImageView.snp.remakeConstraints  { make in
            make.top.equalTo(82)
            make.leading.equalTo(paddingLeft)
            make.width.height.equalTo(24)
        }
        
        audioTitleLabel.setContentCompressionResistancePriority(.init(751), for: .horizontal)
        audioTitleLabel.setContentHuggingPriority(.required, for: .horizontal)
        audioTitleLabel.snp.remakeConstraints  { make in
            make.leading.equalTo(audioImageView.snp.trailing).offset(8)
            make.centerY.equalTo(audioImageView)
        }
        audioNameLabel.setContentCompressionResistancePriority(.init(749), for: .horizontal)
        audioNameLabel.snp.remakeConstraints { make in
            make.leading.equalTo(audioTitleLabel.snp.trailing).offset(8)
            make.centerY.equalTo(audioTitleLabel)
            make.height.equalTo(40)
        }
        
        rightArrowImageView.setContentCompressionResistancePriority(.init(800), for: .horizontal)
        rightArrowImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rightArrowImageView.snp.remakeConstraints { make in
            make.trailing.equalToSuperview().inset(paddingRight)
            make.centerY.equalTo(audioImageView)
            make.leading.equalTo(audioNameLabel.snp.trailing).offset(8)
        }
        
        grayLine.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(paddingLeft)
            make.trailing.equalToSuperview().inset(paddingRight)
            make.top.equalTo(audioImageView.snp.bottom).offset(18)
            make.height.equalTo(1)
        }
        
        soundMinimumButton.snp.remakeConstraints { make in
            make.top.equalTo(grayLine.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(paddingLeft)
            make.width.height.equalTo(20)
        }
        
        soundMaximumButton.snp.remakeConstraints { make in
            make.trailing.equalToSuperview().inset(paddingRight)
            make.centerY.equalTo(soundMinimumButton)
            make.width.height.equalTo(soundMinimumButton)
        }
        
        soundSlider.snp.remakeConstraints { make in
            make.leading.equalTo(soundMinimumButton.snp.trailing).offset(12)
            // 间隔增加2像素，感官上更对程
            make.trailing.equalTo(soundMaximumButton.snp.leading).offset(-12 - 2)
            make.centerY.equalTo(soundMinimumButton)
            make.height.equalTo(60)
            make.bottom.equalToSuperview().inset(4).priority(.high)
        }

    }

}
