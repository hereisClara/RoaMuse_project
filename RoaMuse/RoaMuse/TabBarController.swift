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
        
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground() // 确保背景不透明
            appearance.backgroundColor = UIColor(named: "backgroundGray") // 设置背景颜色
            appearance.shadowImage = nil // 移除阴影图片
            appearance.shadowColor = nil // 移除阴影颜色
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.clear]
            
            tabBar.scrollEdgeAppearance = appearance // 适用于滚动边缘的外观
            tabBar.standardAppearance = appearance // 适用于常规的外观
        } else {
            // 对于 iOS 15 以下的系统版本，移除阴影和背景
            let appearance = UITabBarAppearance()
            tabBar.shadowImage = UIImage()  // 移除阴影
            tabBar.backgroundImage = UIImage() // 移除背景图片
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.clear]
        }
        
        // 确保背景颜色和其他样式生效
        tabBar.barTintColor = UIColor(named: "backgroundGray")
        tabBar.backgroundColor = UIColor(named: "backgroundGray")
        tabBar.tintColor = UIColor(resource: .deepBlue)
        tabBar.unselectedItemTintColor = UIColor.lightGray
//        tabBar.isTranslucent = false // 禁用透明效果
        
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
        
        tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)  // 調整圖標位置
    }
}
