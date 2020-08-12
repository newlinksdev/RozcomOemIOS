
import Foundation
import RozcomOem

extension NSDictionary {
    func toQBHUser() -> ROPanel {
        let currentUser = AccountManager.getTenant()!
        let qbId = self["sender"] as! Int
        let qbLogin = self["user_id_sender"] as! Int
        let name = self["sender_name"] as! String
        let entraceId = self["entrance_id"] as! Int
        let callType = self["caller_type"] as! Int
        let called = self["callId"] as! String
        let panelId = self["panel_id"] as! Int
        
        let panel = ROPanel(buildingId: currentUser.buildingId!, apartmentNo: currentUser.apartmentNo!, isSecurity: callType, name: name, qbId: qbId, qbLogin: "\(qbLogin)")
        panel.entranceId = entraceId
        panel.callId = called
        panel.id = panelId
        return panel
    }
}
