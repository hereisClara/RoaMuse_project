//
//  FirstViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/16.
//

import Foundation
import UIKit

class FirstViewController: UIViewController {
    
    var shouldLogin = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        if shouldLogin {
            
            let loginVC = LoginViewController()
            let navController = UINavigationController(rootViewController: loginVC)
            addChild(navController)
            view.addSubview(navController.view)
            navController.view.frame = view.bounds
            navController.didMove(toParent: self)
            
        } else {
            
            let tabBarVC = TabBarController()
            addChild(tabBarVC)
            view.addSubview(tabBarVC.view)
            tabBarVC.view.frame = view.bounds
            tabBarVC.didMove(toParent: self)
            
        }
        
    }
    
}
