//
//  PostViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/16.
//

import Foundation
import UIKit
import SnapKit
import FirebaseFirestore

class PostViewController: UIViewController {
    
    let db = Firestore.firestore()
    
    let titleTextField = UITextField()
    let contentTextView = UITextView()
    let postButton = UIButton(type: .system)
    
    var postButtonAction: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        
        view.addSubview(contentTextView)
        view.addSubview(titleTextField)
        view.addSubview(postButton)
        
        contentTextView.backgroundColor = .systemGray5
        titleTextField.backgroundColor = .systemGray6
        
        titleTextField.snp.makeConstraints { make in
            make.bottom.equalTo(contentTextView.snp.top).offset(-20)
            make.height.equalTo(50)
            make.width.equalTo(250)
            make.centerX.equalTo(view)
        }
        
        contentTextView.snp.makeConstraints { make in
            make.width.height.equalTo(250)
            make.center.equalTo(view)
        }
        
        postButton.snp.makeConstraints { make in
            make.top.equalTo(contentTextView.snp.bottom).offset(50)
            make.centerX.equalTo(view)
        }
        
        contentTextView.font = UIFont.systemFont(ofSize: 20)
        postButton.setTitle("發文", for: .normal)
        postButton.addTarget(self, action: #selector(saveData), for: .touchUpInside)
        postButton.addTarget(self, action: #selector(backToLastPage), for: .touchUpInside)
    }
    
//    儲存發文
    @objc func saveData() {
        
        guard let title = titleTextField.text, let content = contentTextView.text else { return }
        
        let posts = Firestore.firestore().collection("posts")
        let document = posts.document()
        
        let data = [
            "id": document.documentID,
            "userId": "yen",
            "title": title,
            "content": content,
            "photoUrl": "photo",
            "createdAt": Date(),
            "bookmarkCount": 5,
            "tripId": "trip01"
        ] as [String : Any]
        
        document.setData(data)
    }
    
    @objc func backToLastPage() {
        
        postButtonAction?()
        navigationController?.popViewController(animated: true)
        
    }
    
}
