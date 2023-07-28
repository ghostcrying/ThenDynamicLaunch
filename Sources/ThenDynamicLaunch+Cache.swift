//
//  ThenDynamicLaunch+Cache.swift
//  ThenDynamicLaunch
//
//  Created by 陈卓 on 2023/7/28.
//

import Foundation

extension ThenDynamicLaunch {
    
    func save(_ key: String, value: Any?) {
        
        guard var dict = UserDefaults.standard.dictionary(forKey: Keys.identifier) else {
            return
        }
        
        if let value = value {
            dict[key] = value
        } else {
            dict.removeValue(forKey: key)
        }
        
        UserDefaults.standard.setValue(dict, forKey: Keys.identifier)
        UserDefaults.standard.synchronize()
    }
    
    func value(_ key: String) -> String? {
        
        guard let dict = UserDefaults.standard.dictionary(forKey: Keys.identifier) else {
            return nil
        }
        
        return dict[key] as? String
    }
    
}
