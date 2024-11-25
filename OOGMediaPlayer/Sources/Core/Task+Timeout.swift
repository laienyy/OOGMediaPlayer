//
//  Task+Timeout.swift
//  OOGMediaPlayer
//
//  Created by XinCore on 2024/11/25.
//

import Foundation

func excute<T>(timeout: TimeInterval, task: @escaping () async throws -> T) async throws -> T {
    
    let fetchTask = Task {
        let result = try await task()
        try Task.checkCancellation()
        return result
    }
        
    let timeoutTask = Task {
        try await Task.sleep(nanoseconds: UInt64(timeout) * NSEC_PER_SEC)
        // 取消正常流程需执行的Task
        fetchTask.cancel()
        // 返回超时Error
        throw OOGMediaPlayerError.TaskError.timeout
    }
    
    do {
        let result = try await fetchTask.value
        timeoutTask.cancel()
        return result
    } catch let error {
        throw fetchTask.isCancelled ? OOGMediaPlayerError.TaskError.timeout : error
    }
}
