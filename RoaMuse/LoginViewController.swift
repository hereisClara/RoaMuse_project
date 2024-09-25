import Foundation
import UIKit
import SnapKit
import FirebaseFirestore
import FirebaseAuth

class LoginViewController: UIViewController {
    
    let orangeLoginButton = UIButton(type: .system)
    let blueLoginButton = UIButton(type: .system)
    let db = Firestore.firestore()
    let testButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundGray
        setupUI()
    }
    
    func setupUI() {
        view.addSubview(orangeLoginButton)
        view.addSubview(blueLoginButton)
        
        view.addSubview(testButton)
        
        orangeLoginButton.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.centerY.equalTo(view).offset(-50)
            make.width.height.equalTo(80)
        }
        
        orangeLoginButton.backgroundColor = .orange
        orangeLoginButton.layer.cornerRadius = 40
        
        orangeLoginButton.setTitle("登入", for: .normal)
        orangeLoginButton.setTitleColor(.white, for: .normal)
        
        orangeLoginButton.addTarget(self, action: #selector(didTapOrangeLoginButton), for: .touchUpInside)
        
        blueLoginButton.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.centerY.equalTo(view).offset(50)
            make.width.height.equalTo(80)
        }
        
        testButton.snp.makeConstraints { make in
            make.bottom.equalTo(view).offset(-100)
            make.width.height.equalTo(60)
            make.centerX.equalTo(view)
        }
        
        testButton.setTitle("test", for: .normal)
        testButton.backgroundColor = .red
        testButton.layer.cornerRadius = 20
        
        blueLoginButton.backgroundColor = .blue
        blueLoginButton.layer.cornerRadius = 40
        
        blueLoginButton.setTitle("登入", for: .normal)
        blueLoginButton.setTitleColor(.white, for: .normal)
        
        blueLoginButton.addTarget(self, action: #selector(didTapBlueLoginButton), for: .touchUpInside)
        testButton.addTarget(self, action: #selector(tapTestBtn), for: .touchUpInside)
    }
    
    @objc func tapTestBtn() {
        let testVC = TestVC()
//        testVC.view.backgroundColor = .blue
        self.present(testVC, animated: true, completion: nil)
    }
    
    @objc func didTapOrangeLoginButton() {
        saveUserData(userName: "@yen")
        
        let tabBarController = TabBarController()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        }
    }
    
    @objc func didTapBlueLoginButton() {
        saveUserData2(userName: "@zann")
        
        let tabBarController = TabBarController()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        }
    }
    
    func saveUserData(userName: String) {
        let usersCollection = Firestore.firestore().collection("users")
        let userId = "Am5Jsa1tA0IpyXMLuilm"  // 固定 ID
        
        // 查詢是否已存在相同的 userName
        usersCollection.whereField("userName", isEqualTo: userName).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("查詢失敗: \(error.localizedDescription)")
                return
            }
            
            if let snapshot = querySnapshot, !snapshot.isEmpty {
                // 已經存在相同的 userName，但仍然將資料保存到 UserDefaults
                print("userName 已存在，直接更新 UserDefaults")
                UserDefaults.standard.set(userName, forKey: "userName")
                UserDefaults.standard.set(userId, forKey: "userId")
                UserDefaults.standard.set("@900623", forKey: "email")
                print("資料保存到 UserDefaults")
            } else {
                // userName 不存在，新增資料並保存到 UserDefaults
                let newDocument = usersCollection.document(userId)
                
                let data = [
                    "id": userId,
                    "userName": userName,
                    "email": "@900623"
                ]
                
                newDocument.setData(data) { error in
                    if let error = error {
                        print("資料上傳失敗：\(error.localizedDescription)")
                    } else {
                        // 保存成功，將資料存入 UserDefaults
                        UserDefaults.standard.set(userName, forKey: "userName")
                        UserDefaults.standard.set(userId, forKey: "userId")
                        UserDefaults.standard.set("@900623", forKey: "email")
                        print("資料上傳成功，並保存到 UserDefaults！")
                    }
                }
            }
        }
    }
    
    func saveUserData2(userName: String) {
        let usersCollection = Firestore.firestore().collection("users")
        let userId = "UItPd5mGpUcpxQc2nGyy"  // 固定 ID
        
        // 查詢是否已存在相同的 userName
        usersCollection.whereField("userName", isEqualTo: userName).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("查詢失敗: \(error.localizedDescription)")
                return
            }
            
            if let snapshot = querySnapshot, !snapshot.isEmpty {
                // 已經存在相同的 userName，但仍然將資料保存到 UserDefaults
                print("userName 已存在，直接更新 UserDefaults")
                UserDefaults.standard.set(userName, forKey: "userName")
                UserDefaults.standard.set(userId, forKey: "userId")
                UserDefaults.standard.set("@900516", forKey: "email")
                print("資料保存到 UserDefaults")
            } else {
                // userName 不存在，新增資料並保存到 UserDefaults
                let newDocument = usersCollection.document(userId)
                
                let data = [
                    "id": userId,
                    "userName": userName,
                    "email": "@900516"
                ]
                
                newDocument.setData(data) { error in
                    if let error = error {
                        print("資料上傳失敗：\(error.localizedDescription)")
                    } else {
                        // 保存成功，將資料存入 UserDefaults
                        UserDefaults.standard.set(userName, forKey: "userName")
                        UserDefaults.standard.set(userId, forKey: "userId")
                        UserDefaults.standard.set("@900516", forKey: "email")
                        print("資料上傳成功，並保存到 UserDefaults！")
                    }
                }
            }
        }
    }
}
