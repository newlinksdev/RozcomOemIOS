# Demo for RozcomOem 

Client for  Rozcom - OEM X500

How to use:

1. - Setup RozcomOem:

  ```RozcomOem.setup(applicationID: applicationID, authKey: authKey, authSecret: authSecret, accountKey: accountKey, apiEndPoint: apiEndPoint, chatEndpoint: chatEndpoint)```


2. - Login and Connect to QuickBlox:

    Need to add this on start application and became active

```
if let user = AcountManager.getUser() {
    ROLoginManager.instance.connectToQuickBlox(quickBloxUserId: user.qbId, password: user.qbPassword!, quickBloxLogin: user.qbLogin, completion: { (error) in
        print("error connection to quickblox: \(error)")
    })
}
```

3. - Authenticate:

-  ```ROAPIManager.sharedInstance.getAuth(phone: inputedPhone)``` - Login

- ```ROAPIManager.sharedInstance.getUserDetails(phone: phoneNumber, authCode: tfLogin.text)``` - Verification

4. - Get list panels and monitors:

param isMons set to true for get monitors and false to get panels(default false)
- ```ROAPIManager.sharedInstance.getListEntrance(building: user.buildingId!, isMons: Bool)```

5. - Managers:

	```ROVideoChatManager, ROChatManager``` - managers for call and chat

6. - UI

 - ```ROCallView, RORecieveCallView``` - view for call and receive call

 - ```ROChatViewController``` - viewcontroller for chat


 Usage: 
 ```
 let chatViewController = ROChatViewController()
 chatViewController.currentTenant = currentTenant    
 chatViewController.oponentPanel = receiveCallPanel 
 ```
  
Function setup for set image and label titles:
```
setup(endCall: UIImage, openAll: UIImage, openDoor: UIImage, gateText: String, sureOpenGateText: String, userBusyText: String)
```



# Important thing
        
 Before release to appstore need to remove unneeded architecture(Because we can`t upload framework that support simulator to appstore):

    1. Find RozcomOem in you pods
    2. Right click and select show in finder
    3. Open it in terminal
    4. In terminal run: lipo -remove x86_64 -output RozcomOem.framework/RozcomOem RozcomOem.framework/RozcomOem


For continue run in simulators need to run :

    1. pod deintegrate
    2. pod install

