
import UIKit
import RozcomOem

class PushManager: NSObject {
    
    static let shared = PushManager()
    
    func registerForRemoveNotification() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, _ in
                if granted {
                    UNUserNotificationCenter.current().getNotificationSettings {(settings) in
                        guard settings.authorizationStatus == .authorized else { return }
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                }
        })
        UNUserNotificationCenter.current().delegate = self
    }
    
    func sendPushToken() {
        guard let user = AccountManager.getUser() else { return }
        let token = UserDefaults.standard.string(forKey: Constants.Params.token)
        PushClient.instanse.registerDevice(qbId: user.qbId, token: token ?? "")
    }
    
    func handlePush(pushDic: [AnyHashable : Any]) {
        NSLog("pushDic = \(pushDic.description)")
        guard
            let alert = pushDic["message"] as? NSDictionary
            else {
                return
        }
        guard let _ = AccountManager.getUser() else { return }
        if let topViewController = topViewController() {
            if topViewController is UINavigationController {
                let lastVC = (topViewController as! UINavigationController).children.last
                let isFreeNow = (lastVC is HomeViewController && (lastVC as! HomeViewController).homeState == .free )
                NSLog("isFreeNow \(isFreeNow)")
                if isFreeNow {
                    guard let home = lastVC as? HomeViewController else { return }
                    let oponentPanel = alert.toQBHUser()
                    home.startReceiveCall(panel: oponentPanel)
                }
            }
        }
    }
    
    func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        return controller
    }
}

extension PushManager: UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NSLog(userInfo.description)
        handlePush(pushDic: userInfo)
        completionHandler(.newData)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        NSLog(notification.request.content.userInfo.description)
        handlePush(pushDic: notification.request.content.userInfo)
        completionHandler([])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NSLog(response.notification.request.content.description)
        handlePush(pushDic: response.notification.request.content.userInfo)
        completionHandler()
    }
}
