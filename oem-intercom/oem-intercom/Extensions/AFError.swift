//
//  AFError.swift
//  DemoRozcomOem
//
//  Created by Developer on 11.06.2020.
//  Copyright © 2020 Test. All rights reserved.
//

import Alamofire

extension AFError {
    func getErrorCode() -> Int? {
        switch self {
        case .responseValidationFailed(let reason):
            switch reason {
            case .unacceptableStatusCode(let code):
                return code
            default:
                return nil
            }
        default:
            return nil
        }
    }
}
