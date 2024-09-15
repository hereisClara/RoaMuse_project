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
            make.centerY.equalTo(view.snp.centerY).offset(-40)
        }
        
        passwordLabel.snp.makeConstraints { make in
            make.trailing.equalTo(view.snp.centerX).offset(-20)
            make.centerY.equalTo(view.snp.centerY)
        }
        
        userNameLabel.snp.makeConstraints { make in
            make.trailing.equalTo(view.snp.centerX).offset(-20)
            make.centerY.equalTo(view.snp.centerY).offset(40)
        }
        
        accountTextField.snp.makeConstraints { make in
            make.trailing.equalTo(view.snp.centerX).offset(-20)
            make.centerY.equalTo(view.snp.centerY).offset(-40)
            make.width.equalTo(view).multipliedBy(0.3)
        }
        
        passwordTextField.snp.makeConstraints { make in
            make.trailing.equalTo(view.snp.centerX).offset(-20)
            make.centerY.equalTo(view.snp.centerY)
            make.width.equalTo(view).multipliedBy(0.3)
        }
        
        userNameTextField.snp.makeConstraints { make in
            make.trailing.equalTo(view.snp.centerX).offset(-20)
            make.centerY.equalTo(view.snp.centerY).offset(40)
            make.width.equalTo(view).multipliedBy(0.3)
        }
        
        accountTextField.layer.borderWidth = 1
        passwordTextField.layer.borderWidth = 1
        userNameTextField.layer.borderWidth = 1
        
    }
    
}
