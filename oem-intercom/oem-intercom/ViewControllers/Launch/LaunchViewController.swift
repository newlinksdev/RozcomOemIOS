//
//  LaunchViewController.swift
//  DemoRozcomOem
//
//  Created by Developer on 12.08.2020.
//  Copyright © 2020 Test. All rights reserved.
//

import UIKit
import RozcomOem
import Alamofire

class LaunchViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.openClient(mobile: "0969064802")
        }
    }
    
    private func openClient(mobile: String) {
        ProgressManager.show()
        ROAPIManager.sharedInstance.openClient(mobile: mobile) { [weak self] (result) in
            ProgressManager.success()
            guard let self = `self` else { return }
            switch result {
            case .success(let tenant):
                tenant.phone = mobile
                if UIDevice.current.userInterfaceIdiom == .pad {
                    self.toMonitorsVC(user: tenant)
                } else {
                    AccountManager.setTenant(tenant: tenant)
                    PushManager.shared.sendPushToken()
                    HomeViewController.presentAsRoot()
                }
            case .failure(let error):
                if let afError = error as? AFError, let errorCode = afError.getErrorCode(), errorCode == 422 {
                    self.alert(message: "user_not_exist".localized)
                } else {
                    self.alert(message: error.localizedDescription)
                }
            }
        }
    }
    
    private func toMonitorsVC(user: ROTenant) {
        ROAPIManager.sharedInstance.getListMons(buildingId: user.buildingId!) { [weak self] (result) in
            switch result {
            case . success(let listMons):
                let filteredMonitors = listMons.filter({$0.apartmentNo == user.apartmentNo})
                if filteredMonitors.isEmpty {
                    self?.alert(title: "no_monitor_for_number".localized)
                } else {
                    let monitorsVC = Storyboard.main.instanceOf(viewController: ListMonitorsViewController.self, identifier: "ListMonitorsViewController")!
                    monitorsVC.currentUser = user
                    monitorsVC.listMonitors = filteredMonitors
                    AppDelegate.shared.window?.rootViewController = monitorsVC
                }
            case .failure(let error):
                self?.alert(title: error.localizedDescription)
            }
        }
    }
}
