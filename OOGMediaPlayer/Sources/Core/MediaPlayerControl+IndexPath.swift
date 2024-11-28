//
//  MediaPlayerControl+IndexPath.swift
//  OOGMediaPlayer
//
//  Created by XinCore on 2024/11/25.
//

import Foundation


//MARK: - IndexPath 相关

public extension MediaPlayerControl {
    
    /**
     *  根据条件计算 `上一个` 播放位置
     *
     *  获取基于当前索引的前一个索引，返回`none` =  需停止播放
     */
    func getPreviousIndexPath() -> IndexPath? {
        guard isExistsValidMedia() else {
            // 当前无有效多媒体，停止播放
            log(prefix: .mediaPlayer, "Not found valid item")
            return nil
        }
        
        guard let indexPath = currentIndexPath else {
            // 当前无有效下标，返回首个播放顺序
            return getValidMediaIndexPaths().first
        }

        switch loopMode {
        case .single:
            // 单曲循环
            return currentIndexPath
            
        case .shuffle:
            // 随机循环
            return getValidMediaRandomIndexPath()
            
        case .album:
            // 歌单、专辑循环
            
            guard isExistsValidMedia() else {
                return nil
            }

            let list = getValidMediaIndexPaths(at: indexPath.section)
            let index = list.firstIndex(of: indexPath) ?? 0
            guard index > 0 else {
                return list.last // 当前是一个，返回歌单最后一个
            }
            return list[index - 1]
            
        case .order:
            // 顺序循环
            
            let list = getValidMediaIndexPaths()
            let index = list.firstIndex(of: indexPath) ?? 0
            guard index > 0 else {
                return list.last // 当前是一个，返回歌单最后一个
            }
            
            return list[index - 1]
            
        case .none:
            // 不循环
            
            let list = getValidMediaIndexPaths()
            let index = list.firstIndex(of: indexPath) ?? 0
            guard index > 0 else {
                return list.last // 当前是一个，返回歌单最后一个
            }
            return list[index - 1]
        }
    }
    
    /**
     *  根据条件计算 `下一个` 播放的位置
     *
     *  获取基于当前索引的`下一个`索引，返回`none` =  需停止播放
     */
    func getNextMediaIndexPath() -> IndexPath? {
        
        guard isExistsValidMedia() else {
            // 当前无有效多媒体，停止播放
            log(prefix: .mediaPlayer, "Not found valid item")
            return nil
        }
        
        guard let indexPath = currentIndexPath else {
            // 当前无有效下标，返回首个播放顺序
            return getValidMediaIndexPaths().first
        }

        switch loopMode {
        case .single:
            // 单曲循环
            return currentIndexPath
            
        case .shuffle:
            // 随机循环 （已有指定的播放位置则返回指定的位置）
            return nextIndexPathForShuffleLoop ?? getValidMediaRandomIndexPath()
            
        case .album:
            // 歌单、专辑循环
            
            guard isExistsValidMedia() else {
                return nil
            }

            let list = getValidMediaIndexPaths(at: indexPath.section)
            let index = list.firstIndex(of: indexPath) ?? 0
            guard index < list.count - 1 else {
                return list.first // 最后一个，返回歌单第一个
            }
            return list[index + 1]
            
        case .order:
            // 顺序循环
            
            let list = getValidMediaIndexPaths()
            let index = list.firstIndex(of: indexPath) ?? 0
            guard index < list.count - 1 else {
                return list.first // 最后一个，返回第一个
            }
            
            return list[index + 1]
            
        case .none:
            // 不循环
            
            let list = getValidMediaIndexPaths()
            let index = list.firstIndex(of: indexPath) ?? 0
            guard index < list.count - 1 else {
                return nil // 最后一个，不再继续播放
            }
            return list[index + 1]
        }
        
    }
    
}

public extension MediaPlayerControl {
    
    /// Index是否有效（是否越界、是否有数据）
    func isValidIndexPath(_ indexPath: IndexPath) -> Bool {
        guard indexPath.section < getItems().count else {
            return false
        }
        guard indexPath.row < getItems()[indexPath.section].mediaList.count else {
            return false
        }
        return true
    }
    
    ///  IndexPath 是否是当前二维列表的最后一个
    func isLastIndexPathInItems(_ indexPath: IndexPath) -> Bool {
        guard let indexPath = currentIndexPath else {
            return false
        }
        guard indexPath.section == getItems().count - 1 else {
            return false
        }
        guard indexPath.row == getItems()[indexPath.section].mediaList.count - 1 else {
            return false
        }
        return true
    }
    
    /// 获取歌曲在所有专辑中的首个位置（允许存在多个相同ID的多媒体）
    func indexPathOf(mediaID: Int) -> IndexPath? {
        for section in getItems().enumerated() {
            if let index = section.element.mediaList.firstIndex(where: { $0.resId == mediaID }) {
                return .init(row: index, section: section.offset)
            }
        }
        return nil
    }
    
    /// 获取歌曲在所有专辑中的所有位置（允许存在多个相同ID的多媒体）
    func indexPathListOf(mediaId: Int) -> [IndexPath] {
        var result = [IndexPath]()
        for section in getItems().enumerated() {
            if let index = section.element.mediaList.firstIndex(where: { $0.resId == mediaId }) {
                result.append(.init(row: index, section: section.offset))
            }
        }
        return result
    }
    
    /// 获取随机一个有效多媒体下标
    func getValidMediaRandomIndexPath() -> IndexPath? {
        let list = getValidMediaIndexPaths()
        guard list.count > 0 else {
            return nil
        }
        var randomGenerator = SystemRandomNumberGenerator()
        let randomInt = Int.random(in: 0..<list.count, using: &randomGenerator)
        let indexPath = list[randomInt]
        return indexPath
    }
    
    /// 获取有效多媒体的下标列表
    func getValidMediaIndexPaths() -> [IndexPath] {
        // 便利并返回有效的多媒体的indexPath
        let validIndexPaths = getItems().enumerated().map { getValidMediaIndexPaths(at: $0.offset) }
        let indexPaths = validIndexPaths.flatMap({ $0 })
        return indexPaths
    }
    
    
    /// 获取某`Section`有效多媒体的的下标列表
    func getValidMediaIndexPaths(at section: Int) -> [IndexPath] {
        guard getItems().count > section else {
            return []
        }
        let indexPaths = getItems()[section].mediaList.enumerated().compactMap { element in
            // 有效则返回indexPath，否则返回nil
            return element.element.isValid ? IndexPath(row: element.offset, section: section) : nil
        }
        return indexPaths
    }
    
}
