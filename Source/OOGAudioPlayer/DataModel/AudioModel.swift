//
//  BackgroundSong.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/22.
//

import Foundation

// MARK: - 音乐

public class AudioModel: NSObject {
    
    public var id: Int = 0
    /// 数据ID
    public var resId: Int = 0
    /// 音频文件url
    public var audio: String?
    /// 音频时长
    public var audioDuration: Int?
    /// 音频文件名称
    public var audioName: String?
    /// 封面图
    public var coverImgUrl: String?
    /// 详情图
    public var detailImgUrl: String?
    /// 显示名称
    public var displayName: String?
    /// 音频名称
    public var musicName: String?
    /// 音频类型（关联字典表）
    public var musicType: String?
    /// App短链接
    public var shortLink: String?
    // 0不收费 1收费
    public var subscription: Bool = false
    
    public var useCache: Bool = true
    
    public var isFavorite: Bool = false
    

    //MARK: - Play Status ( LocalMediaPlayable )
    
    /// 播放状态
    public var status: LocalMediaStatus = .idle
    /// 播放状态变化回调
    public var statusChangedActions: [AnyHashable: StatusChangedClosure] = [:]
    
    public func observeStatusChanged(_ observer: AnyHashable, _ action: @escaping StatusChangedClosure) {
        statusChangedActions[observer] = action
    }
    
    public func removeStatusObserver(_ observer: AnyHashable) {
        statusChangedActions[observer] = nil
    }
    
    /// 设置新状态
    public func setNewPlayerStatus(_ status: LocalMediaStatus) {
        self.status = status
        self.statusChangedActions = self.statusChangedActions.filter({
            let keepLife = $0.value(self, status)
//            if !keepLife {
//                print("StatusChangedClosure is removed")
//            }
            return keepLife
        })
    }
    
    //MARK: File Download Status ( Protocol: Downloadable )
    
    var downloadProgressChangedActions: [AnyHashable: DownloadStatusChangedClosure] = [:]
    /// 文件状态
    public var downloadProgress: FileDownloadProgress = .normal
    /// 下载请求
    public var downloadRequest: DownloadRequest?
    /// 更新文件状态状态
    public func observeDownloadProgress(_ observer: AnyHashable, progression: @escaping DownloadStatusChangedClosure) {
        downloadProgressChangedActions[observer] = progression
    }
    
    public func removeDownloadProgressObserver(_ observer: AnyHashable) {
        downloadProgressChangedActions[self] = nil
    }
    
    public func updateFileProgress(_ progress: FileDownloadProgress) {
        downloadProgress = progress
        // 回调并释放掉需要释放的closure
        DispatchQueue.main.async {
            self.downloadProgressChangedActions = self.downloadProgressChangedActions.filter({ $0.value(self, progress) })
        }
    }
    
    public override var description: String {
        return "ID: \(id), 《 \(musicName ?? "") 》, Subscription - \(subscription)"
    }
}


extension AudioModel: BGMSong {

    /// 文件下载链接
    public var fileUrlString: String? {
        return audio
    }
    /// 文件名
    public var fileName: String {
        return musicName ?? ""
    }
    /// 是否有效
    public var isValid: Bool {
        return !subscription
    }
    
    /// 取消下载
    public func cancelFileDownload() {
        print("Download Request Status: \(downloadRequest?.task?.state.rawValue ?? -1) - \(downloadRequest?.url.relativePath ?? "none")" )
        downloadRequest?.task?.cancel()
        print("Download Request Status: \(downloadRequest?.task?.state.rawValue ?? -1) - \(downloadRequest?.url.relativePath ?? "none")" )
    }
    
    /// 获取本地文件URL
    public func getLocalFileUrl() async throws -> URL {    
        guard let urlString = audio else {
            throw NSError(domain: "Media Url is nil", code: -1)
        }
        
        if useCache,
           let fileInfo = FileItem.getCache(key: urlString),
           fileInfo.isDataValid() { 
            // 返回缓存
            updateFileProgress(.downloaded)
            print("Find cache for: 《 \(fileInfo.fileName) 》")
            return fileInfo.asFilePathUrl()
        }
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Media Url invalid", code: -1)
        }
        
        updateFileProgress(.downloading(0.0))
        /**
         * 无进度下载方式
         */
//        let data = try await URLSession.shared.download(url: url)
        
        
        /**
         * 有进度下载方式
         */
        
        let request = DownloadRequest(url: url)
        downloadRequest = request
        
        let data = try await request.fetchDataInProgress(progress: .init(queue: .main, callback: { [weak self] progress in
            self?.updateFileProgress(.downloading(progress.percentComplete))
            if progress.isFinished {
                self?.updateFileProgress(.downloaded)
            }
        }))
        
        let filePath = FileItem.bgm(fileName)
        try filePath.write(data: data)
        // 根据网络链接存储缓存文件路径
        filePath.storeFilePath(key: urlString)
        
        print("Download Request Finished: \(downloadRequest?.task?.state.rawValue ?? -1) - \(downloadRequest?.url.relativePath ?? "none")" )
        
        return filePath.asFilePathUrl()
    }
    
}
