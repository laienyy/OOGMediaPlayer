//
//  Download.swift
//  BGMManagerSample
//
//  Created by YiYuan on 2024/10/11.
//

import Foundation

struct ProgressHandler {
    typealias Callback = (Progress) -> Void
    
    var queue: DispatchQueue = .main
    var callback: Callback
}

extension Progress {
    var percentComplete: Double {
        return Double(completedUnitCount) / Double(totalUnitCount)
    }
}

public class DownloadRequest: NSObject {
    
    public var task: URLSessionDataTask?
    
    var url: URL
    var timeoutInterval: TimeInterval
    
    init(url: URL, timeoutInterval: TimeInterval = 60) {
        self.url = url
        self.timeoutInterval = timeoutInterval
    }
    
    deinit {
        log(prefix: .mediaPlayer, "Download Request released -", url)
    }
    
    func fetchDataInProgress(progress: ProgressHandler?) async throws -> Data {
        let progressHandler = progress
        
        log(prefix: .mediaPlayer, "Start downloading - \(url.relativePath)")
        let (asyncBytes, urlResponse) = try await URLSession.shared.bytes(from: url)
        
        task = asyncBytes.task
        
        // 增加超时
        let response =  try await excute(timeout: timeoutInterval) { [weak self] in
            
            guard let `self` = self else {
                throw OOGMediaPlayerError.DownloadError.requestRelease
            }
            
            let length = (urlResponse.expectedContentLength)
            var data = Data.init(capacity: Int(length))
            
            let progress = Progress(totalUnitCount: length)
            // 有必要回调的进度最小变化
            let callbackGranularity = Int(Double(length) * 0.002)
            
            // 记录已经完成的进度
            var preProgress: Int = 0
            
//                log(prefix: .mediaPlayer, "Start Sleep")
//                try await Task.sleep(nanoseconds: 1_000_000_000 * 5)
//                log(prefix: .mediaPlayer, "End Sleep")
            
            for try await byte in asyncBytes {
                data.append(byte)
                
                if let handler = progressHandler {
                    
                    // 计算下载进度
                    let diff = data.count - preProgress
                    // 降低回调频率，过滤回调次数过多的问题
                    let isNesessaryToCallback = diff > callbackGranularity || data.count == length
                    guard isNesessaryToCallback else {
                        continue
                    }
                    
                    preProgress = Int(data.count)
                    progress.completedUnitCount = Int64(data.count)
                    
                    log(prefix: "Download", String(format: "Progress: %ld / %ld - %.1f%%  -- (\(self.url.relativePath))",
                                                   progress.completedUnitCount,
                                                   progress.totalUnitCount,
                                                   progress.percentComplete * 100))
                    
                    handler.queue.async { progressHandler?.callback(progress) }
                }
            }
            
            log(prefix: .mediaPlayer, "Downloading finished - \(self.url.relativePath) (\(data.count / 1024) KB)")
            return data
        }
        
        log(prefix: .mediaPlayer, "Downloading finished - \(self.url.relativePath) (\(response.count / 1024) KB)")
        
        return response
    }
    
    public func cancel() {
        task?.cancel()
    }
}

//extension URLSession {
//    
//    func download(url: URL) async throws -> Data {
//        
//        let (fileTempUrl, response) = try await URLSession.shared.download(from: url)
//        
//        guard let httpResponse = response as? HTTPURLResponse /* OK */ else {
//            throw NSError(domain: "HTTP request response invalid", code: -1)
//        }
//        
//        guard httpResponse.statusCode == 200 else {
//            throw NSError(domain: "HTTP request response code invalid", code: httpResponse.statusCode)
//        }
//        
//        return try Data(contentsOf: fileTempUrl)
//    }
//    
//    func fetchDataInProgress(url: URL, progress: ProgressHandler? = nil) async throws -> Data {
//        let progressHandler = progress
//        
//        log(prefix: .mediaPlayer, "[Download] Start downloading - \(url.relativePath)")
//        let (asyncBytes, urlResponse) = try await URLSession.shared.bytes(from: url)
//        
//        let length = (urlResponse.expectedContentLength)
//        var data = Data()
//        data.reserveCapacity(Int(length))
//        
//        let progress = Progress(totalUnitCount: length)
//        
//        // 有必要回调的进度最小变化
//        let callbackGranularity = Int(Double(length) * 0.002)
//        
//        var preProgress: Int = 0
//        
//        
//        for try await byte in asyncBytes {
//            
//            data.append(byte)
//            
//            if let handler = progressHandler {
//                
//                let diff = data.count - preProgress
//                // 降低回调频率，过滤回调次数过多的问题
//                let isNesessaryToCallback = diff > callbackGranularity || data.count == length
//                guard isNesessaryToCallback else {
//                    continue
//                }
//                
//                preProgress = Int(data.count)
//                progress.completedUnitCount = Int64(data.count)
//                
//                log(prefix: .mediaPlayer, String(format: "[Download] Progress: %ld / %ld - %.1f%%",
//                                         progress.completedUnitCount,
//                                         progress.totalUnitCount,
//                                         progress.percentComplete * 100))
////                
//                handler.queue.async { progressHandler?.callback(progress) }
//            }
//        }
//        
//        log(prefix: .mediaPlayer, "Downloading finished - \(url.relativePath) (\(data.count / 1024) KB)")
//        
//        return data
//    }
//}
