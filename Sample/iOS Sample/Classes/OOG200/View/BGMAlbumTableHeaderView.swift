//
//  BGMAlbumTableHeaderView.swift
//  iOS Sample
//
//  Created by YiYuan on 2024/11/1.
//

import UIKit

class BGMAlbumTableHeaderView: UIView {

    let whiteContentView = UIView()
    let titleLabel = UILabel()
    let shuffleSwitch = UISwitch()
    
    var contentEdgeInsets: UIEdgeInsets = .init(top: 12, left: 16, bottom: 16, right: 16) {
        didSet {
            reloadWhiteContentConstrains()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialization()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        initialization()
    }
    
    func initialization() {
        whiteContentView.layer.cornerRadius = 4
        whiteContentView.layer.masksToBounds = true
        whiteContentView.backgroundColor = .white
        addSubview(whiteContentView)
        reloadWhiteContentConstrains()
        
        whiteContentView.addSubview(titleLabel) { make in
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(60)
            make.top.bottom.equalToSuperview()
        }
        whiteContentView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        whiteContentView.addSubview(shuffleSwitch) { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16).priority(.high)
            make.centerY.equalToSuperview()
        }
    }
    
    func reloadWhiteContentConstrains() {
        whiteContentView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(contentEdgeInsets.left)
            make.trailing.equalToSuperview().inset(contentEdgeInsets.right)
            make.top.equalToSuperview().offset(contentEdgeInsets.top)
            make.bottom.equalToSuperview().inset(contentEdgeInsets.bottom)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
//        whiteContentView =
    }
}
