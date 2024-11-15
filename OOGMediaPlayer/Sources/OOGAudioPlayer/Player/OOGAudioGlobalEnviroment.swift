//
//  OOGAudioGlobalEnviroment.swift
//  OOGMediaPlayer
//
//  Created by YiYuan on 2024/11/15.
//

import Foundation

/// 播放器全局变量
public class OOGAudioGlobalEnviroment {
    public static let share = OOGAudioGlobalEnviroment()
    
    /// 用户是否已订阅
    public var isIAPIActive: Bool = false
}
