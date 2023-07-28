//
//  Keys.swift
//  ThenDynamicLaunch
//
//  Created by 陈卓 on 2023/7/28.
//

import Foundation

struct Keys {
    
    static let identifier = "com.then.launch"
    
    enum Version: String {
        case `default` = "com.then.launch.version"
        case check     = "com.then.launch.version.check"
    }
    
    enum Path: String {
        case root = "com.then.launch.path.root"
        case tmp  = "com.then.launch.path.tmp"
    }
    
    enum BackUp: String {
        /// 系统启动图备份key
        case system = "com.then.launch.path.backup.system"
        /// 自定义启动图备份key
        case custom = "com.then.launch.path.backup.custom"
        
        /// 启动图备份路径
        var cachePath: String? {
            guard let directory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
                return nil
            }
            let path = directory + "/" + rawValue
            if FileManager.default.fileExists(atPath: path) == false {
                do {
                    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print(error.localizedDescription)
                    return nil
                }
            }
            return path
        }
    }
    
}
