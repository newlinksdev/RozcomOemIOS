//
//  PushClient.swift
//  DemoRozcomOem
//
//  Created by Developer on 14.05.2020.
//  Copyright © 2020 Test. All rights reserved.
//

import Foundation
import Alamofire
import RozcomOem

final class PushClient {
    static let instanse = PushClient()
    
    let apiUrl = "http://oem.drozcomapp.com/api"
    let headers: HTTPHeaders = ["Accept":"application/json", "Content-Type": "application/json"]
    
    let deviceRegister = "/device/register"
    
    private init() { }
    
    func registerDevice(qbId: Int, token: String) {
        let params: [String: Any] = ["os": 1,
                                     "qb_id": qbId,
                                     "token": token]
        
        let registerUrl = apiUrl + deviceRegister
        
        let request = AF.request(registerUrl, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<300)
            .responseJSON { (response) in
                print(response)
                switch response.result {
                case .success(_):
                    NSLog("success \(#function)")
                case .failure(let error):
                    NSLog("error \(#function) \(error.localizedDescription)")
                }
        }
        request.cURLDescription { (curl) in
            print(curl)
        }
    }
}
