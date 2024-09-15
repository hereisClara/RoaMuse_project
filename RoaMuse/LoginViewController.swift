//
//  LoginViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/15.
//

import Foundation
import UIKit
import SnapKit

class LoginViewController: UIViewController {
    
    
    let accountLabel = UILabel()
    let passwordLabel = UILabel()
    let userNameLabel = UILabel()
    let accountTextField = UITextField()
    let passwordTextField = UITextField()
    let userNameTextField = UITextField()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    func setupUI() {
        
        view.addSubview(accountLabel)
        view.addSubview(passwordLabel)
        view.addSubview(userNameLabel)
        view.addSubview(accountTextField)
        view.addSubview(passwordTextField)
        view.addSubview(userNameTextField)
        
        accountLabel.snp.makeConstraints { make in
            make.trailing.equalTo(view.snp.centerX).offset(-20)
            make.centerY.equalTo(view.snp.centerY).offset(-60)
        }
        
        passwordLabel.snp.makeConstraints { make in
            make.trailing.equalTo(view.snp.centerX).offset(-20)
            make.centerY.equalTo(view.snp.centerY)
        }
        
        userNameLabel.snp.makeConstraints { make in
            make.trailing.equalTo(view.snp.centerX).offset(-20)
            make.centerY.equalTo(view.snp.centerY).offset(60)
        }
        
        accountTextField.snp.makeConstraints { make in
            make.leading.equalTo(view.snp.centerX).offset(20)
            make.centerY.equalTo(view.snp.centerY).offset(-60)
            make.width.equalTo(view).multipliedBy(0.4)
            make.height.equalTo(40)
        }
        
        passwordTextField.snp.makeConstraints { make in
            make.leading.equalTo(view.snp.centerX).offset(20)
            make.centerY.equalTo(view.snp.centerY)
            make.width.equalTo(view).multipliedBy(0.4)
            make.height.equalTo(40)
        }
        
        userNameTextField.snp.makeConstraints { make in
            make.leading.equalTo(view.snp.centerX).offset(20)
            make.centerY.equalTo(view.snp.centerY).offset(60)
            make.width.equalTo(view).multipliedBy(0.4)
            make.height.equalTo(40)
        }
        
        accountLabel.text = "account"
        passwordLabel.text = "password"
        userNameLabel.text = "username"
        
        accountTextField.layer.borderWidth = 1
        passwordTextField.layer.borderWidth = 1
        userNameTextField.layer.borderWidth = 1
        
    }
    
}
