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
        
        tabBar.tintColor = UIColor(resource: .deepBlue)
        tabBar.unselectedItemTintColor = UIColor.lightGray

        let homeVC = HomeViewController()
        let homeNavController = UINavigationController(rootViewController: homeVC)
        homeVC.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "house"), tag: 0)
        

        let collectionsVC = CollectionsViewController()
        let collectionsNavController = UINavigationController(rootViewController: collectionsVC)
        collectionsVC.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "bookmark"), tag: 1)
        
        let establishVC = EstablishViewController()
        let establishNavController = UINavigationController(rootViewController: establishVC)
        establishVC.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "plus"), tag: 2)
        
        let newsFeedVC = NewsFeedViewController()
        let newsFeedNavController = UINavigationController(rootViewController: newsFeedVC)
        newsFeedVC.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "globe"), tag: 3)
        
        let userVC = UserViewController()
        let userNavController = UINavigationController(rootViewController: userVC)
        userVC.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "person"), tag: 4)

        self.viewControllers = [homeNavController, collectionsNavController, establishNavController, newsFeedNavController, userNavController]
    }
}
