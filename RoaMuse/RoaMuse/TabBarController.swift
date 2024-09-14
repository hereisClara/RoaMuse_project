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
        
        tabBar.tintColor = UIColor(resource: .deepBlue)
        tabBar.unselectedItemTintColor = UIColor.lightGray

        let homeVC = HomeViewController()
        homeVC.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "house"), tag: 0)
        

        let collectionsVC = CollectionsViewController()
        collectionsVC.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "heart"), tag: 1)
        
        let establishVC = EstablishViewController()
        establishVC.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "plus"), tag: 2)
        
        let newsFeedVC = NewsFeedViewController()
        newsFeedVC.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "globe"), tag: 3)
        
        let userVC = UserViewController()
        userVC.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "person"), tag: 4)

        self.viewControllers = [homeVC, collectionsVC, establishVC, newsFeedVC, userVC]
    }
}
