//
//  FullScreenImageViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/6.
//

import Foundation
import UIKit
import SnapKit

class FullScreenImageViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var images: [UIImage] = []
    var startingIndex: Int = 0
    var pageViewController: UIPageViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupPageViewController()
        setupPanGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func setupPageViewController() {
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        let initialVC = viewControllerForPage(at: startingIndex)
        pageViewController.setViewControllers([initialVC], direction: .forward, animated: true, completion: nil)
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        
        pageViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func viewControllerForPage(at index: Int) -> ImageViewController {
        let imageVC = ImageViewController()
        imageVC.image = images[index]
        imageVC.index = index
        return imageVC
    }
    
    // 获取前一页
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let imageVC = viewController as? ImageViewController,
              imageVC.index > 0 else { return nil }
        
        return viewControllerForPage(at: imageVC.index - 1)
    }
    
    // 获取下一页
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let imageVC = viewController as? ImageViewController,
              imageVC.index < images.count - 1 else { return nil }
        
        return viewControllerForPage(at: imageVC.index + 1)
    }
    
    func setupPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGesture)
    }
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)  // 取得滑動的位移

        switch gesture.state {
        case .changed:
            // 根據手指滑動的距離調整 view 的垂直位置
            if translation.y > 0 {  // 下滑
                view.transform = CGAffineTransform(translationX: 0, y: translation.y)
            } else if translation.y < 0 {  // 上滑
                view.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
            
        case .ended:
            // 如果滑動距離超過 150，則關閉控制器，否則回彈
            if abs(translation.y) > 150 {
                dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.view.transform = .identity  // 回彈到原始位置
                }
            }
            
        default:
            break
        }
    }

}
