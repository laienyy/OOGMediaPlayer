//
//  AudioAlbumTableHeaderFooterView.swift
//  iOS Sample
//
//  Created by YiYuan on 2024/10/23.
//

import UIKit

class AudioAlbumTableHeaderFooterView: UIView {
    
    @IBOutlet weak var coverImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var loopButton: UIButton!
    
    var loopAction: ((AudioAlbumTableHeaderFooterView) -> Void)?
    
    @IBAction func loopButtonPressed(_ sender: Any) {
        loopAction?(self)
    }

}
