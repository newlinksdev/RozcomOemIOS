
import UIKit
import RozcomOem

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let urls = [
        "stun:turn.quickblox.com",
        "turn:turn.quickblox.com:3478?transport=udp",
        "turn:turn.quickblox.com:3478?transport=tcp"
    ]
    let password = "baccb97ba2d92d71e26eb9886da5f1e0";
    let userName = "quickblox";
    
    let applicationID: UInt = 10
    let authKey = "VY2qS6eRgnyeEbp"
    let authSecret = "K3GWUgvnREzOLOV"
    let accountKey = "DvPrfp9hAAbyPsz9sR9j"
    let apiEndPoint = "https://apirozcom.quickblox.com"
    let chatEndpoint = "chatrozcom.quickblox.com"
//        let applicationID: UInt = 5
//        let authKey = "jMe8pwaepNR64GZ"
//        let authSecret = "2DGFXpDth89zbax"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        RozcomOem.setup(applicationID: applicationID, authKey: authKey, authSecret: authSecret, accountKey: accountKey, apiEndPoint: apiEndPoint, chatEndpoint: chatEndpoint)
        RozcomOem.setupQuickBloxICE(urls: urls, userName: userName, password: password)
        tryReconnectToQuickBlox()
        PushManager.shared.registerForRemoveNotification()
        showLoginIfNeeded()
        if let removeNotification = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [String: Any] {
            PushManager.shared.handlePush(pushDic: removeNotification)
        }
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        ROChatManager.instance.disconnect()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        tryReconnectToQuickBlox()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        ROChatManager.instance.disconnect()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02hhx", $0) }.joined()
        print("token", token)
        UserDefaults.standard.set(token, forKey: Constants.Params.token)
        PushManager.shared.sendPushToken()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        debugPrint(error.localizedDescription)
    }
    
    func tryReconnectToQuickBlox() {
        if let user = AcountManager.getUser() {
            ROLoginManager.instance.connectToQuickBlox(quickBloxUserId: user.qbId, password: user.qbPassword!, quickBloxLogin: user.qbLogin, completion: { (error) in
                print("error connection to quickblox: \(error)")
            })
        }
    }
    
    private func showLoginIfNeeded() {
        if AcountManager.getUser() == nil {
            let loginVC = Storyboard.login.instanceOf(viewController: UINavigationController.self)!
            window?.rootViewController = loginVC
            self.window!.makeKeyAndVisible()
        } else {
            HomeViewController.presentAsRoot()
        }
    }
}

extension AppDelegate {
    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    var rootViewController: UIViewController {
        return window!.rootViewController!
    }
}
