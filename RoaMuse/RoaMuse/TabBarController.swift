//
//  TabBarController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/12.
//

import Foundation
import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let homeVC = HomeViewController()
        homeVC.tabBarItem = UITabBarItem(title: "首頁", image: UIImage(systemName: "house"), tag: 0)

        let collectionsVC = CollectionsViewController()
        collectionsVC.tabBarItem = UITabBarItem(title: "收藏", image: UIImage(systemName: "heart"), tag: 1)
        
        let establishVC = EstablishViewController()
        establishVC.tabBarItem = UITabBarItem(title: "建立", image: UIImage(systemName: "plus"), tag: 2)
        
        let newsFeedVC = NewsFeedViewController()
        newsFeedVC.tabBarItem = UITabBarItem(title: "動態", image: UIImage(systemName: "globe"), tag: 3)
        
        let userVC = UserViewController()
        userVC.tabBarItem = UITabBarItem(title: "個人", image: UIImage(systemName: "person"), tag: 4)

        self.viewControllers = [homeVC, collectionsVC, establishVC, newsFeedVC, userVC]
    }
}
