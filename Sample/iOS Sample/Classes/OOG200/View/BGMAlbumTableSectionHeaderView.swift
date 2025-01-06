//
//  BGMAlbumTableHeaderView.swift
//  iOS Sample
//
//  Created by YiYuan on 2024/10/31.
//

import UIKit

typealias SimpleAction<T> = (T) -> Void

class BGMAlbumTableSectionHeaderView: UITableViewHeaderFooterView {

    let headerContentView = UIView()
    
    let coverImageView = UIImageView()
    let coverGrayBg1 = UIView()
    let coverGrayBg2 = UIView()
    
    let specialIconImageView = UIImageView()
    var specIconImage: UIImage? {
        didSet {
            specialIconImageView.image = specIconImage
            specialIconImageView.isHidden = specIconImage == nil
            
            coverImageView.isHidden = specIconImage != nil
            coverGrayBg1.isHidden = specIconImage != nil
            coverGrayBg2.isHidden = specIconImage != nil
        }
    }
    
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let shuffleButton = UIButton(type: .custom)
    let loopButton = UIButton(type: .custom)
    let foldButton = UIButton(type: .custom)
    
    var isLoop: Bool {
        get { loopButton.isSelected }
        set { loopButton.isSelected = newValue }
    }
    var isFold: Bool {
        get { foldButton.isSelected }
        set { foldButton.isSelected = newValue }
    }
    var isShuffle: Bool {
        get { shuffleButton.isSelected }
        set { shuffleButton.isSelected = newValue }
    }
    
    
    
    var loopAction: SimpleAction<BGMAlbumTableSectionHeaderView>?
    var foldAction: SimpleAction<BGMAlbumTableSectionHeaderView>?
    var shuffleAction: SimpleAction<BGMAlbumTableSectionHeaderView>?
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        initialization()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        specIconImage = nil
    }
    
    func initialization() {
        
        coverImageView.backgroundColor = #colorLiteral(red: 0.9360449314, green: 0.9360449314, blue: 0.9360449314, alpha: 1)
        
        coverGrayBg1.backgroundColor = #colorLiteral(red: 0.8764976859, green: 0.8761957288, blue: 0.8667587638, alpha: 1)
        coverGrayBg2.backgroundColor = #colorLiteral(red: 0.9246129394, green: 0.9245135188, blue: 0.9214245081, alpha: 1)
        
        coverImageView.layer.cornerRadius = 4
        coverGrayBg1.layer.cornerRadius = 4
        coverGrayBg2.layer.cornerRadius = 4
        
        coverImageView.layer.masksToBounds = true
        coverGrayBg1.layer.masksToBounds = true
        coverGrayBg2.layer.masksToBounds = true
        
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        subtitleLabel.font = .systemFont(ofSize: 13)
        titleLabel.text = "Album Name"
        subtitleLabel.text = "Number of songs"
        
        shuffleButton.setImage(UIImage(named: "icon_random_loop"), for: .normal)
        shuffleButton.setImage(UIImage(named: "icon_random_loop_sel"), for: .selected)
        
        loopButton.setImage(UIImage(named: "bgm_list_loop"), for: .normal)
        loopButton.setImage(UIImage(named: "bgm_list_loop_selected"), for: .selected)
        
        foldButton.setImage(UIImage(named: "bgm_list_fold"), for: .normal)
        foldButton.setImage(UIImage(named: "bgm_list_unfold"), for: .selected)
        
        loopButton.addTarget(self, action: #selector(loopButtonPressed), for: .touchUpInside)
        foldButton.addTarget(self, action: #selector(foldButtonPressed), for: .touchUpInside)
        shuffleButton.addTarget(self, action: #selector(shuffleButtonPressed), for: .touchUpInside)
            
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(foldButtonPressed))
        
        headerContentView.addGestureRecognizer(tapRecognizer)
        headerContentView.backgroundColor = .white
        headerContentView.layer.masksToBounds = true
        contentView.addSubview(headerContentView) { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().priority(.high)
        }
        
        
        headerContentView.addSubviews(specialIconImageView, coverGrayBg2, coverGrayBg1, coverImageView, titleLabel, subtitleLabel, shuffleButton, loopButton, foldButton)
        
        coverImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16).priority(.high)
            make.width.height.equalTo(56)
        }
        
        coverGrayBg1.snp.makeConstraints { make in
            make.leading.equalTo(coverImageView).offset(4)
            make.trailing.equalTo(coverImageView).offset(4)
            make.top.equalTo(coverImageView).inset(3)
            make.bottom.equalTo(coverImageView).inset(3)
        }
        
        coverGrayBg2.snp.makeConstraints { make in
            make.leading.equalTo(coverGrayBg1).offset(4)
            make.trailing.equalTo(coverGrayBg1).offset(4)
            make.top.equalTo(coverImageView).inset(5)
            make.bottom.equalTo(coverImageView).inset(5)
        }
        
        specialIconImageView.snp.makeConstraints { make in
            make.leading.equalTo(coverImageView)
            make.width.equalTo(coverImageView).offset(7)
            make.top.equalTo(coverImageView)
            make.bottom.equalTo(coverImageView)
        }
        
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(coverImageView.snp.trailing).offset(17)
            make.top.equalTo(coverImageView).offset(7)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.bottom.equalTo(coverImageView).inset(7)
        }
        
        shuffleButton.snp.makeConstraints { make in
            let width = 40 as CGFloat
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(72 - (width - 32) - 8).priority(.high)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(width)
        }
        
        loopButton.snp.makeConstraints { make in
            let width = 40 as CGFloat
            make.leading.equalTo(shuffleButton.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(72 - (width - 32) / 2).priority(.high)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(width)
        }
        
        foldButton.snp.makeConstraints { make in
            make.leading.equalTo(loopButton.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(16).priority(.high)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
    }
    
    func setLoop(_ isLoop: Bool) {
        loopButton.isSelected = isLoop
    }
    
    @objc func loopButtonPressed() {
        loopAction?(self)
    }
    
    @objc func foldButtonPressed() {
        foldAction?(self)
    }
    
    @objc func shuffleButtonPressed() {
        shuffleAction?(self)
    }

    func updateCorner(isFirst: Bool, isLast: Bool, isFold: Bool) {
        
        self.isFold = isFold
        
        headerContentView.layer.cornerRadius = 8
        
        if isFirst, isLast {
            if isFold {
                headerContentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner,
                                                         .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            } else {
                headerContentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            }
        } else if isFirst {
            headerContentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if isLast, isFold {
            headerContentView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            headerContentView.layer.maskedCorners = []
        }
        
    }
}
