//
//  ListMonitorsViewController.swift
//  DemoRozcomOem
//
//  Created by Developer on 27.01.2020.
//  Copyright © 2020 Test. All rights reserved.
//

import UIKit
import RozcomOem

class ListMonitorsViewController: UIViewController {

    @IBOutlet private weak var btnNext: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    
    var currentUser: ROTenant!
    var listMonitors: [ROMonitor]!
    var selectedMonitor: ROMonitor!
    
//    MARK:- Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
//    MARK:- IBAction
    @IBAction private func btnNextClicked(_ sender: Any) {
        ProgressManager.show()
        ROLoginManager.instance.loginToQuickBlox(quickBloxLogin: currentUser.qbLogin, password: currentUser.qbPassword!) { [weak self] (result) in
            ProgressManager.success()
            guard let `self` = self else { return }
            switch result {
            case .success(_):
                AcountManager.setUser(user: self.currentUser)
                PushManager.shared.sendPushToken()
                HomeViewController.presentAsRoot()
            case .failure(let error):
                self.alert(title: error.localizedDescription)
            }
        }
    }
}

//  MARK:- UITableViewDelegate and UITableViewDataSource
extension ListMonitorsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        listMonitors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MonitorTableViewCell") as! MonitorTableViewCell
        cell.setMonitor(listMonitors[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedMonitor = listMonitors[indexPath.row]
        currentUser.apartmentNo = selectedMonitor.apartmentNo
        currentUser.firstName = selectedMonitor.firstName
        currentUser.lastName = selectedMonitor.lastName
        currentUser.qbId = selectedMonitor.qbId
        currentUser.qbPassword = selectedMonitor.qbPassword
        btnNext.isHidden = false
    }
}
