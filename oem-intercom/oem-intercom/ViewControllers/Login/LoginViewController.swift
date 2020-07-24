

import UIKit
import Alamofire
import RozcomOem

enum LoginState {
    case login, verification
}

class LoginViewController: UIViewController {
    
    //    MARK: - IBOutlet
    @IBOutlet private weak var btnLogin: UIButton!
    @IBOutlet private weak var tfLogin: UITextField!
    @IBOutlet private weak var lblTitle: UILabel!
    @IBOutlet private weak var btnBack: UIButton!
    
    var authCode: Int?
    var phoneNumber: String!
    var state: LoginState = .login {
        didSet {
            if state == .verification {
                btnBack.isHidden = false
                lblTitle.text = "enter_code".localized
                tfLogin.text = ""
            } else {
                btnBack.isHidden = true
                lblTitle.text = "enter_phone".localized
                tfLogin.text = ""
            }
        }
    }
    
    //    MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        state = .login
    }
    
    //   MARK: - IBAction
    @IBAction private func btnBackClicked(_ sender: Any) {
        state = .login
    }
    
    @IBAction private func btnLoginClicked(_ sender: UIButton) {
        let inputedPhone = tfLogin.text!
        switch state {
        case .login:
            guard !inputedPhone.isEmpty else {
                self.alert(message: "empty_phone".localized)
                return
            }
            ProgressManager.show()
            ROAPIManager.sharedInstance.getAuth(phone: inputedPhone) { [weak self] (result) in
                ProgressManager.success()
                guard let `self` = self else { return }
                switch result {
                case .success(let code):
                    self.phoneNumber = inputedPhone
                    self.authCode = code
                    self.state = .verification
                case .failure(let err):
                    if let afError = err as? AFError, let errorCode = afError.getErrorCode(), errorCode == 422 {
                        self.alert(message: "user_not_exist".localized)
                    } else {
                        self.alert(message: err.localizedDescription)
                    }
                }
            }
        case .verification:
            guard !tfLogin.text!.isEmpty else {
                self.alert(message: "empty_code".localized)
                return
            }
            ProgressManager.show()
            ROAPIManager.sharedInstance.getUserDetails(phone: phoneNumber, authCode: tfLogin.text!) { [weak self] (result) in
                ProgressManager.success()
                guard let `self` = self else { return }
                switch result {
                case .success(let user):
                    user.phone = self.phoneNumber
                    UserDefaults.standard.set("0", forKey: Constants.Params.ptt)
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        self.toMonitorsVC(user: user)
                    } else {
                        AccountManager.setUser(user: user)
                        PushManager.shared.sendPushToken()
                        HomeViewController.presentAsRoot()
                    }
                case .failure(let err):
                    if let afError = err as? AFError, let errorCode = afError.getErrorCode(), errorCode == 403 {
                        self.alert(message: "invalid_code".localized)
                    } else {
                        self.alert(message: err.localizedDescription)
                    }
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
