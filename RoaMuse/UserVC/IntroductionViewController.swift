//
//  IntroductionViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/6.
//

import Foundation
import UIKit
import FirebaseFirestore
import SnapKit

protocol IntroductionViewControllerDelegate: AnyObject {
    func introductionViewControllerDidSave(_ intro: String)
}

class IntroductionViewController: UIViewController {

    let textView = UITextView()
    weak var delegate: IntroductionViewControllerDelegate?
    var currentBio: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        setupTextView()
        setupNavigationBar()
        
        textView.text = currentBio
    }

    func setupTextView() {
        view.addSubview(textView)
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.cornerRadius = 10.0

        textView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.leading.equalTo(view.snp.leading).offset(16)
            make.trailing.equalTo(view.snp.trailing).offset(-16)
            make.height.equalTo(200)
        }
    }

    // 設置導航欄按鈕
    func setupNavigationBar() {
        navigationItem.title = "個人簡介"
        let saveButton = UIBarButtonItem(title: "保存", style: .done, target: self, action: #selector(saveBio))
        navigationItem.rightBarButtonItem = saveButton
    }

    // 保存個人簡介
    @objc func saveBio() {
        let bioText = textView.text ?? ""
        delegate?.introductionViewControllerDidSave(bioText)
        self.dismiss(animated: true, completion: nil)
    }
}
