//
//  AudioTableViewCell.swift
//  iOS Sample
//
//  Created by YiYuan on 2024/10/23.
//

import UIKit
import OOGMediaPlayer

class AudioTableViewCell: UITableViewCell {

    enum Status {
        case idle
        case downloading
        case playing
        case pause
    }
    
    @IBOutlet weak var playingIconView: UIImageView!
    @IBOutlet weak var downloadProgressLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var loopButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    
    var favoriteAction: ((AudioTableViewCell) -> Void)?
    var loopAction: ((AudioTableViewCell) -> Void)?
    
    
    private var isCurrentPlay: Bool = false
    private var model: (any BGMSong)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        favoriteAction = nil
        loopAction = nil
        
        isCurrentPlay = false
        
        downloadProgressLabel.text = ""
        playingIconView.isHidden = true
        downloadProgressLabel.isHidden = true
    }
    
    func setIsCurrentPlay(_ isCurrentPlay: Bool) {
        self.isCurrentPlay = isCurrentPlay
        reloadSubViews()
    }
    
    @IBAction func favoriteButtonPressed(_ sender: Any) {
        favoriteAction?(self)
        favoriteButton.isSelected = !favoriteButton.isSelected
        if let model = model {
            UserDefaults.standard.set(favoriteButton.isSelected, forKey: "favorite-\(model.id)")
        }
    }
    
    @IBAction func loopButtonPressed(_ sender: Any) {
        loopAction?(self)
    }
    
    func loadModel(_ model: BGMSong, isLoop: Bool) {
        self.model = model
        
        nameLabel.text = model.displayName
        loopButton.isSelected = isLoop
        reloadProgressLabel(with: model.downloadProgress)
        
        model.observeDownloadProgress(self) { [weak self] model, status in
            guard let `self` = self else { return false }
            guard self.model != nil, self.model?.id == model.id else {
                return false
            }
            self.reloadProgressLabel(with: status)
            return true
        }
        
        reloadSubViews()
    }
    
    func setFavorite(_ isFavorite: Bool) {
        favoriteButton.isSelected = isFavorite
    }
    
    func reloadSubViews() {
        playingIconView.isHidden = !isCurrentPlay
        nameLabel.textColor = isCurrentPlay ? #colorLiteral(red: 0.1409692764, green: 0.62271595, blue: 0.375109911, alpha: 1) : .darkGray
        nameLabel.font = .systemFont(ofSize: 15, weight: isCurrentPlay ? .medium : .regular)
    }
    
    func reloadProgressLabel(with status: FileDownloadProgress) {
        
        guard isCurrentPlay else {
            downloadProgressLabel.isHidden = true
            return
        }
        
        switch status {
        case .normal, .failed(_), .downloaded:
            downloadProgressLabel.text = ""
            downloadProgressLabel.isHidden = true
        case .downloading(let progress):
            guard isCurrentPlay else {
                return
            }
            if downloadProgressLabel.isHidden {
                downloadProgressLabel.isHidden = false
            }
            
            downloadProgressLabel.text = "\(Int(progress * 100))%"
        @unknown default:
            downloadProgressLabel.isHidden = true
            downloadProgressLabel.text = ""
        }
    }
}
