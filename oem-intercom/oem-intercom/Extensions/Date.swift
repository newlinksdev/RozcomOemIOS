//
//  Date.swift
//  oem-intercom
//
//  Created by Developer on 27.07.2020.
//  Copyright © 2020 Developer. All rights reserved.
//

import Foundation

extension Date {
    func dayOfWeek() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self).capitalized
    }
}
