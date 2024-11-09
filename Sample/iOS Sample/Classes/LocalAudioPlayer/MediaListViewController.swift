//
//  MediaListViewController.swift
//  MediaPlayerSample
//
//  Created by YiYuan on 2024/10/15.
//

import UIKit
import OOGMediaPlayer

extension NSObject {
//    static func classNameStr() -> String {
//        let cellClassName = NSStringFromClass(Self.self).components(separatedBy: ["."]).last
//        return cellClassName!
//    }
}

extension UITableView {
    func registerFromNib<T: UITableViewCell>(_ cellClass: T.Type, bundle: Bundle? = nil) {
        let cellNib = UINib(nibName: cellClass.classNameStr, bundle: nil)
        register(cellNib, forCellReuseIdentifier: cellClass.classNameStr)
    }
    
    func dequeueReusableCell<T: UITableViewCell>() -> T {
        let cell = dequeueReusableCell(withIdentifier: T.classNameStr)
        return cell as! T
    }
}

class MediaListViewController: UIViewController {

    var playerProvider: LocalAudioPlayerProvider?
    
    var list: [any BGMAlbum] = .init()
    var tableView = UITableView(frame: UIScreen.main.bounds, style: .insetGrouped)
    
    var selectAction: ((MediaListViewController, IndexPath) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Media List"
        
//        let nib = UINib(nibName: "MediaItemTableViewCell", bundle: nil)
//        tableView.register(nib, forCellReuseIdentifier: "MediaItemTableViewCell")
        tableView.registerFromNib(MediaItemTableViewCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        Task {
            do {
//                let info = GetBGMListApiInfo
//                let medias = try await ApiProvider.getBackgroundMedia()
//                print(medias)
            } catch let error {
                print("Get media list failed:", error)
            }
            
        }
        
    }
    
    func setCurrentIndexPath(_ indexPath: IndexPath) {
        tableView.reloadData()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MediaListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list[section].mediaList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = list[indexPath.section].mediaList[indexPath.row]
        
        let cell: MediaItemTableViewCell = tableView.dequeueReusableCell()
        cell.titleLabel.text = item.fileName
        
        
        let isCurrent = indexPath == playerProvider?.currentIndexPath
        cell.rightImageView.image = isCurrent ? .init(systemName: "music.note") : nil
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectAction?(self, indexPath)
    }
}
