//
//  HomeViewController.swift
//  DemoRozcomOem
//
//  Created by Developer on 15.01.2020.
//  Copyright © 2020 Test. All rights reserved.
//

import UIKit
import Quickblox
import RozcomOem
import QuickbloxWebRTC

enum HomeState {
    case receiveCall, calling, free
}

class HomeViewController: UIViewController {

//    MARK: - IBOutlet
    @IBOutlet private weak var lblDoor: UILabel!
    @IBOutlet private weak var lblLeft: UIButton!
    @IBOutlet private weak var btnRight: UIButton!
    @IBOutlet private weak var btnCallUser: UIButton!
    @IBOutlet private weak var lblGuardDoor: UILabel!
    @IBOutlet private weak var btnCallGuard: UIButton!
    @IBOutlet private weak var btnLeftGuard: UIButton!
    @IBOutlet private weak var btnRightGuard: UIButton!
    @IBOutlet private weak var btnDnd: UIButton!
    @IBOutlet private weak var btnPtt: UIButton!
    @IBOutlet private weak var btnAcceptChat: UIButton!
    @IBOutlet private weak var btnOpenDoor: UIButton!
    @IBOutlet private weak var btnOpenGate: UIButton!
    @IBOutlet private weak var startEndCallView: UIView!
    @IBOutlet private weak var btnAcceptCall: UIButton!
    @IBOutlet private weak var btnEndCall: UIButton!
    @IBOutlet private weak var controlButtonsStack: UIStackView!
    @IBOutlet private weak var lblTime: UILabel!
    
    @IBOutlet private weak var callView: ROCallView!
    @IBOutlet private weak var receiveCallView: RORecieveCallView!
    @IBOutlet private weak var constraintsPanelViewBottom: NSLayoutConstraint!
    
    //    MARK: - Property
    public var isConnected: Bool = false
    public var oponentPanelCall: ROPanel!
    public var receiveCallPanel: ROPanel!
    public var homeState: HomeState = .free
    
    private var updateTimeTimer = Timer()
    private var player: AVAudioPlayer?
    private var connectedUserId: NSNumber? = nil
    private var countMessages: Int = 0
    private var callTimer: Timer?
    private var timeForCall: Int!
    private var videoCallStoped: Bool = false
    private var secondsForReceiveCall: Int = Constants.ReceiveCall.secondForReceive
    private var receiveCallTimer: Timer?
    private var isDnd: Bool!
    private var isPPt: Bool!
    private let defaults = UserDefaults.standard
    private let chatManager = ROChatManager.instance
    private var videoChatManager: ROVideoChatManager = .instanse
    private let user = AccountManager.getUser()!
    private var listPanels: [ROPanel] = []
    private var currentIndex: Int = 0
    
    private var selectedPanel: ROPanel? {
        didSet {
            if let value = self.selectedPanel {
                lblDoor.text = value.name
            }
        }
    }
    
    private var listGuards: [ROPanel] = []
    private var currentIndexGuard: Int = 0
    private var selectedGuard: ROPanel? {
        didSet {
            if let value = self.selectedGuard {
                lblGuardDoor.text = value.name
            }
        }
    }
//    MARK:- Class
    class func presentAsRoot() {
        let mainVC = Storyboard.main.instanceOf(viewController: UINavigationController.self)!
        AppDelegate.shared.window?.rootViewController = mainVC
    }
    
//    MARK: - lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        getListUsers()
        setupButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startConnection()
    }
    
    //    MARK: - IBAction
    @IBAction func btnAcceptCallClicked(_ sender: Any) {
        oponentPanelCall = receiveCallPanel
        stopReceiveCall()
        prepareForCall(oponentPanel: oponentPanelCall)
        
    }
    
    @IBAction func btnOpenDoorClicked(_ sender: Any) {
        chatManager.sendMessageWithCustomParams(currentUser: self.user, startParam: ROConstants.Message.openDoor) { (error) in
            if let error = error {
                self.alert(message: error.localizedDescription)
            }
        }
        switch homeState {
        case .receiveCall:
            stopReceiveCall()
        case .calling:
            stopVideoCall()
        case .free:
            return
        }
    }
    
    @IBAction func btnEndCallClicked(_ sender: Any) {
        switch homeState {
        case .receiveCall:
            chatManager.sendMessageWithCustomParams(currentUser: user, startParam: ROConstants.Message.endCall) { (error) -> (Void) in
                print(error)
            }
            stopReceiveCall()
        case .calling:
            stopVideoCall()
        case .free:
            return
        }
    }
    
    @IBAction func btnAcceptChatClicked(_ sender: Any) {
        let chatViewController = ROChatViewController()
        chatViewController.setup(endCall: #imageLiteral(resourceName: "Button_disconnect"),
                                 openAll: #imageLiteral(resourceName: "opBTM"),
                                 openDoor: #imageLiteral(resourceName: "Button_Open"),
                                 gateText: "gate".localized,
                                 sureOpenGateText: "sure_open_gate".localized,
                                 userBusyText: "user_busy".localized)
        chatViewController.currentTenant = user
        chatViewController.oponentPanel = receiveCallPanel
        stopReceiveCall()
        navigationController?.pushViewController(chatViewController, animated: true)
    }
    
    @IBAction func btnOpenGateClicked(_ sender: Any) {
        self.alert(title: "sure_open_all_gates".localized, withCancel: true) { (_) in
            self.openAllDoorTwo()
        }
    }
    
    @IBAction private func btnCallClicked(_ sender: UIButton) {
        if sender == btnCallUser {
            guard let selectedUser = selectedPanel else { return }
            prepareForCall(oponentPanel: selectedUser)
        } else {
            guard let selectedGuard = selectedGuard else { return }
            prepareForCall(oponentPanel: selectedGuard)
        }
    }
    
    @IBAction private func btnRightGuardClicked(_ sender: Any) {
        let newIndex = currentIndexGuard + 1
        if listGuards.indices.contains(newIndex) {
            currentIndexGuard = newIndex
            selectedGuard = listGuards[newIndex]
        }
    }
    
    @IBAction private func btnLeftGuardClicked(_ sender: Any) {
        let newIndex = currentIndexGuard - 1
        if listGuards.indices.contains(newIndex) {
            currentIndexGuard = newIndex
            selectedGuard = listGuards[newIndex]
        }
    }
    
    @IBAction private func btnRightClicked(_ sender: UIButton) {
        let newIndex = currentIndex + 1
        if listPanels.indices.contains(newIndex) {
            currentIndex = newIndex
            selectedPanel = listPanels[newIndex]
        }
    }
    
    @IBAction private func btnLeftClicked(_ sender: UIButton) {
        let newIndex = currentIndex - 1
        if listPanels.indices.contains(newIndex) {
            currentIndex = newIndex
            selectedPanel = listPanels[newIndex]
        }
    }
    
    @IBAction private func dndClicked(_ sender: Any) {
        var dndTitle: String
        if !defaults.bool(forKey: Constants.Params.dnd) {
            isDnd = true
            dndTitle = "on".localized
        } else {
            isDnd = false
            dndTitle = "off".localized
        }
        btnDnd.setTitle(dndTitle, for: .normal)
        sendDataDND()
    }
    
    @IBAction private func pptClicked(_ sender: Any) {
        var pptTitle: String!
        if !defaults.bool(forKey: Constants.Params.ptt) {
            isPPt = true
            defaults.set(isPPt, forKey: Constants.Params.ptt)
            pptTitle = "ppt_off".localized
        } else {
            isPPt = false
            defaults.set(isPPt, forKey: Constants.Params.ptt)
            pptTitle = "ppt_on".localized
        }
        if isConnected {
            setupMicrophoneButton()
        }
        btnPtt.setTitle(pptTitle, for: .normal)
    }
    
    func startReceiveCall(panel: ROPanel) {
        secondsForReceiveCall = Constants.ReceiveCall.secondForReceive
        receiveCallPanel = panel
        updateUIForReceiveCall()
        prepareForReceiveCall()
        playReceiveCallMusic()
        receiveCallTimer =  Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimeReceiveCall), userInfo: nil, repeats: true)
    }
    
    @objc private func updateTimeReceiveCall() {
        if secondsForReceiveCall == 0 && homeState == .receiveCall {
            stopReceiveCall()
        }
        secondsForReceiveCall -= 1
    }
    
    private func updateUIForReceiveCall() {
        receiveCallView.setCallerName(name: receiveCallPanel.name)
        controlButtonsStack.isUserInteractionEnabled = false
        startEndCallView.isHidden = false
        homeState = .receiveCall
        receiveCallView.isHidden = false
        btnAcceptCall.isHidden = false
        btnAcceptChat.isHidden = false
        countMessages = 0
        receiveCallView.getUserPicture(oponentPanel: receiveCallPanel)
    }
    
    func prepareForCall(oponentPanel: ROPanel) {
        let isPTT = defaults.bool(forKey: Constants.Params.ptt)
        videoCallStoped = false
        oponentPanelCall = oponentPanel
        setupQuickBlox()
        updateUIForCall()
        chatManager.createDialod(oponentQuickBloxId: oponentPanel.qbId, closureSuccess: { (_, _) -> (Void) in
            
        }) { (responce) -> (Void) in
            guard !self.videoCallStoped else { return }
            self.alert(message: responce.error?.reasons?.debugDescription ?? "problem_with_internet".localized)
            self.stopVideoCall()
            return
        }
        if QBChat.instance.isConnected {
            chatManager.sendMessageWithCustomParams(currentUser: user, startParam: ROConstants.Message.messageFollowMeHungUp) { (error) -> (Void) in
                print(error)
            }
            videoChatManager.startCall(oponent: oponentPanel,
                                       user: user,
                                       isEnableLocalAudio: isPTT)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                guard !self.videoCallStoped else { return }
                self.prepareForCall(oponentPanel: oponentPanel)
            }
        }
    }
    
    //MARK: - Private
    private func setupMicrophoneButton() {
        let isPTT = defaults.bool(forKey: Constants.Params.ptt)
        callView.btnMicrofone.isHidden = isPTT
        callView.btnMicrofone.setImage(#imageLiteral(resourceName: "micro_red"), for: .normal)
        callView.btnMicrofone.setImage(#imageLiteral(resourceName: "micro_green"), for: .highlighted)
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        longPressGesture.cancelsTouchesInView = false
        callView.btnMicrofone.addGestureRecognizer(longPressGesture)
    }
    
    @objc func longPress(_ sender: UILongPressGestureRecognizer) {
        guard let connectedUserId = connectedUserId else {
            return
        }
        if sender.state == .ended {
            videoChatManager.setLocalAudioEnable(value: false, connectedUserId: connectedUserId)
        }
        if sender.state == .began {
            videoChatManager.setLocalAudioEnable(value: true, connectedUserId: connectedUserId)
        }
    }
    
    @objc private func openAllDoorTwo() {
        for oponent in listPanels {
            chatManager.createDialod(oponentQuickBloxId: oponent.qbId, closureSuccess: { (response, dialog) in
                self.chatManager.sendMessageWithCustomParams(currentUser: self.user, startParam: ROConstants.Message.openDoorTwo) { (error) in
                    if let error = error {
                        self.alert(message: error.localizedDescription)
                    }
                }
            }) { (responce) -> (Void) in
                self.alert(message: responce.error?.reasons?.debugDescription ?? "problem_with_internet".localized)
            }
        }
        if homeState == .calling {
            stopVideoCall()
        } else if homeState == .receiveCall {
            stopReceiveCall()
        }
    }
    
    private func setupButtons() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            constraintsPanelViewBottom.constant = 30
            tick()
            updateTimeTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector:#selector(self.tick) , userInfo: nil, repeats: true)
        }
        let logo = #imageLiteral(resourceName: "logo")
        self.navigationItem.titleView = UIImageView(image: logo)
        let defaults = UserDefaults.standard
        var dndTitle: String
        if !defaults.bool(forKey: Constants.Params.dnd) {
            isDnd = false
            dndTitle = "off".localized
        } else {
            isDnd = true
            dndTitle = "on".localized
        }
        btnDnd.setTitle(dndTitle, for: .normal)
        var pptTitle: String!
        if !defaults.bool(forKey: Constants.Params.ptt) {
            isPPt = false
            pptTitle = "ppt_on".localized
        } else {
            isPPt = true
            pptTitle = "ppt_off".localized
        }
        btnPtt.setTitle(pptTitle, for: .normal)
    }
    
    @objc func tick() {
        let today = Date()
        lblTime.text = today.dayOfWeek() + " " + DateFormatter.localizedString(from: today, dateStyle: .medium, timeStyle: .medium)
    }
    
    private func updateUIForCall() {
        callView.prepareForReuse()
        timeForCall = oponentPanelCall.secondForCall
        homeState = .calling
        controlButtonsStack.isUserInteractionEnabled = false
        callView.isHidden = false
        btnOpenDoor.isEnabled = true
        btnAcceptCall.isHidden = true
        startEndCallView.isHidden = false
        callView.lblConnecting.text = "prepare_to_call".localized
    }
    
    private func stopVideoCall() {
        videoCallStoped = true
        isConnected = false
        homeState = .free
        callView.btnMicrofone.isHidden = true
        controlButtonsStack.isUserInteractionEnabled = true
        callTimer?.invalidate()
        oponentPanelCall = nil
        btnOpenDoor.isEnabled = false
        startEndCallView.isHidden = true
        callView.lblTimer.isHidden = true
        callTimer = nil
        callView.isHidden = true
        connectedUserId = nil
        videoChatManager.stopCall()
    }
    
    private func prepareForReceiveCall() {
        if QBChat.instance.isConnected {
            QBChat.instance.addDelegate(self)
            chatManager.createDialod(oponentQuickBloxId: receiveCallPanel!.qbId, closureSuccess: { [weak self] (_, _) -> (Void) in
                self?.btnOpenDoor.isEnabled = true
                self?.btnAcceptChat.isEnabled = true
            }) { (_) -> (Void) in
                
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.prepareForReceiveCall()
            }
        }
    }
    
    private func playReceiveCallMusic() {
        let urlPath = Bundle.main.url(forResource: "intercom", withExtension: "wav")
        player = try! AVAudioPlayer(contentsOf: urlPath!)
        player?.play()
        player?.numberOfLoops = Int.max
    }
    
    private func stopReceiveCall() {
        controlButtonsStack.isUserInteractionEnabled = true
        startEndCallView.isHidden = true
        btnOpenDoor.isEnabled = false
        btnAcceptChat.isEnabled = false
        homeState = .free
        receiveCallPanel = nil
        receiveCallView.isHidden = true
        receiveCallTimer?.invalidate()
        receiveCallTimer = nil
        player?.stop()
        player = nil
    }
    
    private func setupQuickBlox() {
        QBChat.instance.addDelegate(self)
        QBRTCClient.instance().add(self)
        QBRTCAudioSession.instance().addDelegate(self)
        videoChatManager.initializeAudio()
    }
    
    private func startConnection() {
        let app = (UIApplication.shared.delegate) as! AppDelegate
        app.tryReconnectToQuickBlox()
    }
    
    private func sendDataDND() {
        ProgressManager.show()
        ROAPIManager.sharedInstance.setDND(qblogin: user.qbLogin, dnd: isDnd) { (result) in
            ProgressManager.success()
            switch result {
            case .success(_):
                self.defaults.set(self.isDnd, forKey: Constants.Params.dnd)
            case .failure(let error):
                self.alert(message: error.localizedDescription)
                self.setupButtons()
            }
        }
    }
    
    private func setupTimer() {
        guard callTimer == nil else { return }
        callView.lblTimer.isHidden = false
        updateLabel()
        callTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateLabel), userInfo: nil, repeats: true)
    }
    
    @objc private func updateLabel() {
        if timeForCall == 0 {
            stopVideoCall()
        }
        timeForCall -= 1
        callView.lblTimer.text = "\(Int(timeForCall))"
    }
    
    private func getListUsers() {
        ProgressManager.show()
        ROAPIManager.sharedInstance.getListEntrance(building: user.buildingId!) { [weak self] (result) in
            ProgressManager.success()
            guard let `self` = self else { return }
            switch result {
            case .success(let list):
                self.listPanels = list.filter({$0.isSecurity == 0})
                self.selectedPanel = list.first
                self.listGuards = list.filter({$0.isSecurity != 0})
                print("listGuards", self.listGuards)
                print("listUsers", self.listPanels)
                if !self.listGuards.isEmpty {
                    self.selectedGuard = self.listGuards.first
                }
            case .failure(let error):
                if let _ = error as? ApiError  {
                    self.alert(message: error.localizedDescription, title: "error".localized)
                } else {
                    self.alert(message: error.localizedDescription, title: "error".localized) { (_) in
                        self.getListUsers()
                    }
                }
            }
        }
    }
}

extension HomeViewController: QBRTCClientDelegate {
    public func session(_ session: QBRTCSession, userDidNotRespond userID: NSNumber) {
        guard homeState == .calling else { return }
        alert(message: "user_not_respond".localized, title: "error".localized) { (_) in
            self.stopVideoCall()
        }
    }
    
    public func session(_ session: QBRTCBaseSession, connectedToUser userID: NSNumber) {
        NSLog("session connectedToUser")
        videoChatManager.session?.remoteAudioTrack(withUserID: userID).isEnabled = true
        let isPTT = defaults.bool(forKey: Constants.Params.ptt)
        if isPTT {
            session.localMediaStream.audioTrack.isEnabled = false
        }
        connectedUserId = userID
        session.remoteVideoTrack(withUserID: userID).isEnabled = true
    }
    
    public func sessionDidClose(_ session: QBRTCSession) {
        NSLog("sessionDidClose")
        if session == videoChatManager.session {
            stopVideoCall()
        }
    }
    
    public func session(_ session: QBRTCBaseSession, startedConnectingToUser userID: NSNumber) {
        NSLog("startedConnectingToUser")
        connectedUserId = userID
    }
    
    public func session(_ session: QBRTCSession, hungUpByUser userID: NSNumber, userInfo: [String : String]? = nil) {
        NSLog("hungUpByUser")
        if session.initiatorID == userID {
            session.hangUp([:])
        }
    }
    
    public func session(_ session: QBRTCBaseSession, receivedRemoteVideoTrack videoTrack: QBRTCVideoTrack, fromUser userID: NSNumber) {
        NSLog("receivedRemoteVideoTrack")
        isConnected = true
        setupTimer()
        setupMicrophoneButton()
        callView.qbRemoveVideoView.setVideoTrack(videoTrack)
        callView.qbRemoveVideoView.isHidden = false
        callView.lblConnecting.isHidden = true
    }
}

extension HomeViewController: QBChatDelegate {
    
    public func chatDidReceive(_ message: QBChatMessage) {
        NSLog("chatDidReceive \(message)")
        guard let startParram = message.customParameters[ROConstants.Params.start] as? String else { return }
        if homeState == .calling {
            if startParram == ROConstants.Message.lineBusy {
                alert(message: "user_busy".localized, handlerOk: { (_) in
                    self.stopVideoCall()
                })
            }
        } else if homeState == .receiveCall {
            switch startParram {
            case ROConstants.Message.lineBusy:
                countMessages += 1
                if countMessages == 1 {
                    alert(title: "user_busy".localized) { (_) in
                        self.stopReceiveCall()
                    }
                }
            case ROConstants.Message.openDoorResponse:
                countMessages += 1
                if countMessages == 1 {
                    alert(title: "door_opened".localized) { (_) in
                        self.stopReceiveCall()
                    }
                }
            case ROConstants.Message.loadImage:
                receiveCallView.getUserPicture(oponentPanel: receiveCallPanel)
            case ROConstants.Message.stopRing:
                if let calledId = message.customParameters["callId"] as? String,
                calledId  == receiveCallPanel.callId! {
                    self.stopReceiveCall()
                }
            default:
                return
            }
        }
    }
}

extension HomeViewController: QBRTCAudioSessionDelegate {
    
}


