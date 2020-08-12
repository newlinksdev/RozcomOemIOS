//
//  AcountManager.swift
//  DemoRozcomOem
//
//  Created by Developer on 21.01.2020.
//  Copyright © 2020 Test. All rights reserved.
//

import Foundation
import RozcomOem

class AccountManager {
    static let profile = "profile"
    
    static let userDefaults = UserDefaults.standard
    
    class func setTenant(tenant: ROTenant) {
        let data = NSKeyedArchiver.archivedData(withRootObject: tenant)
        userDefaults.set(data, forKey: profile)
    }
    
    class func getTenant() -> ROTenant? {
        
        guard let decodedUser = userDefaults.object(forKey: profile) as? Data,
            let user = NSKeyedUnarchiver.unarchiveObject(with: decodedUser) as? ROTenant else {
                return nil
        }
        return user
    }
}
