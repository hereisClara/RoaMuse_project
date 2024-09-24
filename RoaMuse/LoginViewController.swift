//
//  LoginViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/15.
//

import Foundation
import UIKit
import SnapKit
import FirebaseFirestore

class LoginViewController: UIViewController {
    
    let loginButton = UIButton(type: .system)
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        self.navigationController?.navigationBar.isHidden = true
        setupUI()
    }
    
    func setupUI() {
        
        view.addSubview(loginButton)
        
        loginButton.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.centerY.equalTo(view).offset(-50)
            make.width.height.equalTo(80)
        }
        
        loginButton.backgroundColor = .accent
        loginButton.layer.cornerRadius = 40
        
        loginButton.setTitle("登入", for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        
        loginButton.addTarget(self, action: #selector(didTapLoginButton), for: .touchUpInside)
        
    }
    
    @objc func didTapLoginButton() {
        
        saveUserData(userName: "@yen")
        
        let tabBarController = TabBarController()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        }
    }
    
    func saveUserData(userName: String) {
        let usersCollection = Firestore.firestore().collection("users")
        
        // 查詢是否已存在相同的 userName
        usersCollection.whereField("userName", isEqualTo: userName).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("查詢失敗: \(error.localizedDescription)")
                return
            }
            
            if let snapshot = querySnapshot, !snapshot.isEmpty {
                // 已經存在相同的 userName
                print("userName 已存在，不能新增")
            } else {
                // userName 不存在，可以新增資料
                let newDocument = usersCollection.document(userId)  // 自動生成 ID
                let data = [
                    "id": userId,
                    "userName": userName,
                    "email": "@900623"
                ]
                
                newDocument.setData(data) { error in
                    if let error = error {
                        print("資料上傳失敗：\(error.localizedDescription)")
                    } else {
                        print("資料上傳成功！")
                    }
                }
            }
        }
    }
}
