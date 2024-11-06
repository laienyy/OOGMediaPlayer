//
//  Logger.swift
//  BGMManagerSample
//
//  Created by YiYuan on 2024/10/11.
//

import Foundation

var logDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd HH:mm:ss.SSS"
//    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return formatter
}()

typealias LogPrefix = String

func log(prefix: LogPrefix?, _ args: Any..., file: String = #file, line: Int = #line) {
    Logger.share.log(prefix: prefix, args, file: file, line: line)
}

class Logger {
    
    static let share = Logger()
    var isEnable: Bool = true
    
    func log(prefix: LogPrefix?, _ args: Any..., file: String = #file, line: Int = #line) {
        guard isEnable else {
            return
        }
        
        let time = logDateFormatter.string(from: Date())
        let fileName = file.components(separatedBy: ["/"]).last!
        let content = args.map { "\($0)" }.joined(separator: " ")
        if let prefix = prefix {
//            print(time, "[\(prefix)] \(fileName)[\(line)]", content)
            print(time, "[\(prefix)]", content)
        } else {
//            print(time, "\(fileName)<\(line)>", content)
            print(time, content)
        }
    }
}
