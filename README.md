# RozcomOemIOS
Client for  Rozcom - OEM X500

How to use:
1. - Setup RozcomOem:
  RozcomOem.setup(applicationID: applicationID, authKey: authKey, authSecret: authSecret, accountKey: accountKey, apiEndPoint: apiEndPoint, chatEndpoint: chatEndpoint)


2. - Login and Connect to QuickBlox:
    Need to add this on start application and became active
if let user = AcountManager.getUser() {
    ROLoginManager.instance.connectToQuickBlox(quickBloxUserId: user.qbId, password: user.qbPassword!, quickBloxLogin: user.qbLogin, completion: { (error) in
        print("error connection to quickblox: \(error)")
    })
}

3. - Authenticate
- ROAPIManager.sharedInstance.getAuth(phone: inputedPhone) - Login 

- ROAPIManager.sharedInstance.getUserDetails(phone: phoneNumber, authCode: tfLogin.text) - Verification

4. - Get list panels and monitors
param isMons set to true for get monitors and false to get panels(default false)
- ROAPIManager.sharedInstance.getListEntrance(building: user.buildingId!, isMons: Bool)

5. - ROVideoChatManager, ROChatManager - managers for call and chat. See example app for. See exapmle app

6. - UI
 - ROCallView, RORecieveCallView - view for call and receive call

 - ROChatViewController - viewcontroller for chat. 
 Usage: 
 		let chatViewController = ROChatViewController()
        chatViewController.currentTenant = currentTenant	
        chatViewController.oponentPanel = receiveCallPanel 
        
        Call setup for set image and label titles:
        setup(endCall: UIImage, openAll: UIImage, openDoor: UIImage, gateText: String, sureOpenGateText: String, userBusyText: String)
