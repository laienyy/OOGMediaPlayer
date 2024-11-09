//
//  BGMAlbumTableFooterView.swift
//  iOS Sample
//
//  Created by YiYuan on 2024/11/1.
//

import UIKit

class BGMAlbumTableSectionFooterView: UITableViewHeaderFooterView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    let whiteView = UIView()
    var edgeInsets: UIEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16) {
        didSet {
            layoutSubviews()
        }
    }
    
    var isLast: Bool = false {
        didSet {
            if isLast {
                whiteView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            } else {
                whiteView.layer.maskedCorners = []
            }
        }
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        initialization()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        initialization()
    }
    
    func initialization() {
        whiteView.backgroundColor = .white
        whiteView.layer.masksToBounds = true
        whiteView.layer.cornerRadius = 8
        contentView.addSubview(whiteView)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        whiteView.frame = contentView.bounds.inset(by: edgeInsets)
    }
    
    
}
