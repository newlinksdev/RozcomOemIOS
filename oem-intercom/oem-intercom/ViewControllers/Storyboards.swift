//
//  Storyboards.swift
//  DemoRozcomOem
//
//  Created by Dev on 12/5/19.
//  Copyright © 2019 Test. All rights reserved.
//

import UIKit

enum Storyboard: String {
    case login = "Login"
    case main = "Main"
    
    var instance: UIStoryboard {
        return UIStoryboard(name: rawValue, bundle: nil)
    }
    
    func instanceOf<T: UIViewController>(viewController: T.Type, identifier viewControllerIdentifier: String? = nil) -> T? {
        if let identifier = viewControllerIdentifier {
            return instance.instantiateViewController(withIdentifier: identifier) as? T
        }
        return instance.instantiateInitialViewController() as? T
    }
}
