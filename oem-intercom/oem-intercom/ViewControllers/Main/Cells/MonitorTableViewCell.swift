//
//  MonitorTableViewCell.swift
//  DemoRozcomOem
//
//  Created by Developer on 27.01.2020.
//  Copyright © 2020 Test. All rights reserved.
//

import UIKit
import RozcomOem

class MonitorTableViewCell: UITableViewCell {

    @IBOutlet private weak var lblTitle: UILabel!
    @IBOutlet private weak var lblDesription: UILabel!
    
    func setMonitor(_ monitor: ROMonitor) {
        lblTitle.text = monitor.firstName
        lblDesription.text = monitor.lastName
    }
}
