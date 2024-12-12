//
//  BackgroundSong.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/10/22.
//

import Foundation

// MARK: - 音频

public class AudioModel: NSObject, Codable {
    
    enum CodingKeys: CodingKey {
        case resId, audio, audioDuration, audioName, coverImgUrl, detailImgUrl, displayName, musicName, musicType, shortLink, subscription, useCache, isFavorite, status
    }
    
    /// 数据ID（唯一标识符）
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
    
    public var isFavorite: Bool = false
    
    // 主要用于debug使用，正常业务逻辑并不会修改为 false
    public var useCache: Bool = true

    
    
    
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
        
        // 回调并释放掉需要释放的closure
        let needsRemoveItems = self.statusChangedActions.filter({ $0.value(self, status) == false })
        needsRemoveItems.forEach { item in
            self.statusChangedActions.removeValue(forKey: item.key)
        }
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
    
    /// 移除下载进度监听
    public func removeDownloadProgressObserver(_ observer: AnyHashable) {
        downloadProgressChangedActions[self] = nil
    }
    
    /// 更新下载进度
    @MainActor public func updateFileProgress(_ progress: FileDownloadProgress) {
        downloadProgress = progress
        
        // 回调并释放掉需要释放的closure
        let needsRemoveItems = self.downloadProgressChangedActions.filter({ $0.value(self, progress) == false })
        needsRemoveItems.forEach { item in
            self.downloadProgressChangedActions.removeValue(forKey: item.key)
        }
    }
    
}


extension AudioModel: BGMSong {
    
    /// 文件下载链接
    public var fileUrlString: String? {
        return audio
    }
    /// 文件名
    public var fileName: String {
        return displayName ?? ""
    }
    /// 是否有效
    public var isValid: Bool {
        // 无需订阅 或者 已订阅 = 可以正常使用
        guard subscription else {
            // 无需订阅
            return true
        }
        return OOGAudioGlobalEnviroment.share.isIAPIActive
    }
    
    /// 取消下载
    public func cancelFileDownload() {
        downloadRequest?.cancel()
        if downloadRequest != nil {
            log(prefix: .mediaPlayer, "Download Request Canceled:", self)
        }
        downloadRequest = nil
        
        Task {
            await updateFileProgress(.failed(OOGMediaPlayerError.DownloadError.canceled))
        }
    }
    
    public func getFileItem() -> FileItem {
        return FileItem.bgm("resID_\(resId).mp3")
    }
    
    public func hasCache() -> Bool {
        return getFileItem().isDataValid()
    }
    
    /// 获取本地文件URL
    public func getLocalFileUrl(timeoutInterval: TimeInterval = 60) async throws -> URL {
        let fileInfo = getFileItem()
        if useCache, fileInfo.isDataValid() {
            // 返回缓存
            await updateFileProgress(.downloaded)
            log(prefix: .mediaPlayer, "Find cache for: 《 \(fileInfo.fileName) 》")
            return fileInfo.asFilePathUrl()
        }
        
        return try await downloadFileData(timeoutInterval: timeoutInterval).asFilePathUrl()
    }
    
    /// 下载文件，下载完成保存至本地，并返回文件信息
    @discardableResult
    public func downloadFileData(timeoutInterval: TimeInterval) async throws -> FileItem {
        
        do {
            
            guard !downloadProgress.isDownloading else {
                throw OOGMediaPlayerError.DownloadError.hasBeenDownloading
            }
            
            guard let urlString = audio else {
                throw OOGMediaPlayerError.DownloadError.requestUrlInvalid
            }
            
            guard let url = URL(string: urlString) else {
                throw OOGMediaPlayerError.DownloadError.requestUrlInvalid
            }
            
            await updateFileProgress(.downloading(0.0))
            /**
             * 无进度下载方式
             */
            //        let data = try await URLSession.shared.download(url: url)
            
            /**
             * 有进度下载方式
             */
            
            let request = DownloadRequest(url: url, timeoutInterval: timeoutInterval, debugInfo: displayName ?? "Unknown")
            downloadRequest = request
            
            let progressHandler: ProgressHandler = .init(queue: .main, callback: { [weak self] progress in
                Task {
                    guard let `self` = self else { return }
                    if self.downloadRequest == nil {
                        await self.updateFileProgress(.failed(OOGMediaPlayerError.DownloadError.canceled))
                        return
                    }
                    await self.updateFileProgress(.downloading(progress.percentComplete))
                    if progress.isFinished {
                        await self.updateFileProgress(.downloaded)
                    }
                }
            })
            
            let data = try await request.fetchDataInProgress(progress: progressHandler)
            
            let fileItem = getFileItem()
            try fileItem.write(data: data)
            // 根据网络链接存储缓存文件路径
            fileItem.storeFilePath(key: urlString)
            
            let stateRawValue = request.task?.state.rawValue ?? -1
            let debugInfo = request.debugInfo
            log(prefix: .mediaPlayer, "Download Request Finished: \(stateRawValue) - \(debugInfo)")
            
            return fileItem
            
        } catch let error {
            
            let err = error as NSError
            if err.domain == NSURLErrorDomain {
                switch err.code {
                case NSURLErrorCancelled:
                    await updateFileProgress(.failed(OOGMediaPlayerError.DownloadError.canceled))
                case NSURLErrorTimedOut:
                    await updateFileProgress(.failed(OOGMediaPlayerError.DownloadError.timeout))
                default:
                    await updateFileProgress(.failed(error))
                }
            } else {
                await updateFileProgress(.failed(error))
            }
            throw error
        }
    }
    
}
