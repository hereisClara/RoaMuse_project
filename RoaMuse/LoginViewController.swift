import Foundation
import AuthenticationServices
import UIKit
import SnapKit
import FirebaseFirestore
import FirebaseAuth

class LoginViewController: UIViewController {
    
    let orangeLoginButton = UIButton(type: .system)
    let blueLoginButton = UIButton(type: .system)
    let db = Firestore.firestore()
    let testButton = UIButton()
    let appleSignInButton = ASAuthorizationAppleIDButton(authorizationButtonType: .default, authorizationButtonStyle: .black)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundGray
        let backgroundImage = UIImage(named: "backgroundImage") // 使用你圖片的名字
        let backgroundImageView = UIImageView(frame: UIScreen.main.bounds) // 設置為全螢幕大小
        backgroundImageView.image = backgroundImage
        backgroundImageView.contentMode = .scaleAspectFill // 設置內容模式（讓圖片適應螢幕大小）
        
        view.insertSubview(backgroundImageView, at: 0)
        checkEULAAgreement()
        setupUI()
        configureAppleSignInButton()
    }
    
    func configureAppleSignInButton() {
        if #available(iOS 13.0, *) {
            self.appleSignInButton.isHidden = false
            appleSignInButton.addTarget(self, action: #selector(didClickAuthorizationAppleIDButton), for: .touchUpInside)
            print("Apple Sign-In Button configured and visible.")
        } else {
            self.appleSignInButton.isHidden = true
            print("Apple Sign-In Button is hidden because iOS version is below 13.0.")
        }
    }
    
    @objc private func didClickAuthorizationAppleIDButton() {
        print("Apple Sign-In Button clicked.")
        if #available(iOS 13.0, *) {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
            print("Authorization request started.")
        } else {
            print("Apple Sign-In not available on this iOS version.")
        }
    }
    
    func checkEULAAgreement() {
        // 檢查是否已同意 EULA
        let isEULAAccepted = UserDefaults.standard.bool(forKey: "EULAAccepted")
        if !isEULAAccepted {
            // 如果尚未同意，顯示對話框
            showEULAAlert()
        }
    }

    func showEULAAlert() {
        let alertController = UIAlertController(title: "End User License Agreement (EULA)",
                                                message: "By using this app, you agree to our terms and conditions. We have a zero-tolerance policy for objectionable content or abusive behavior.",
                                                preferredStyle: .alert)

        let acceptAction = UIAlertAction(title: "Accept", style: .default) { _ in
            // 保存同意狀態
            UserDefaults.standard.set(true, forKey: "EULAAccepted")
            print("User has accepted the EULA.")
        }
        
        let declineAction = UIAlertAction(title: "Decline", style: .destructive) { _ in
            // 若用戶拒絕條款，關閉應用
            print("User declined the EULA, closing app.")
            exit(0)
        }
        
        alertController.addAction(acceptAction)
        alertController.addAction(declineAction)

        self.present(alertController, animated: true, completion: nil)
    }

    
    func setupUI() {
        view.addSubview(appleSignInButton)
        
        appleSignInButton.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.bottom.equalTo(view).offset(-80)
            make.width.equalTo(250)
            make.height.equalTo(50)
        }
    }
    
    @objc func didTapOrangeLoginButton() {
        print("Orange login button tapped.")
        saveUserData(userName: "@yen")
        
        let tabBarController = TabBarController()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        }
    }
    
    @objc func didTapBlueLoginButton() {
        print("Blue login button tapped.")
        saveUserData2(userName: "@zann")
        
        let tabBarController = TabBarController()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        }
    }
    
    func saveUserDataToFirestoreWithApple(id: String, fullName: PersonNameComponents?, email: String?, authorizationCode: String?, identityToken: String?) {
        print("Saving data to Firestore for user: \(id)")
        
        let usersCollection = Firestore.firestore().collection("users")
        
        // 構建用戶資料
        var userData: [String: Any] = [
            "id": id,
            "identityToken": identityToken ?? "",
            "authorizationCode": authorizationCode ?? ""
        ]
        
        // 僅在首次登入時更新 userName 和 email
        if let fullName = fullName {
            let name = [fullName.givenName, fullName.familyName].compactMap { $0 }.joined(separator: " ")
            userData["userName"] = name
        } else {
            print("Full name is nil.")
        }
        
        if let email = email {
            userData["email"] = email
        } else {
            print("Email is nil.")
        }
        
        // 先檢查用戶是否存在
        usersCollection.document(id).getDocument { documentSnapshot, error in
            if let document = documentSnapshot, document.exists {
                print("User already exists, not updating userName or email.")
                // 如果用戶已存在，不覆蓋 userName 和 email
            } else {
                // 如果是新用戶，則將其資料寫入 Firebase
                usersCollection.document(id).setData(userData) { error in
                    if let error = error {
                        print("Error saving user data to Firestore: \(error.localizedDescription)")
                    } else {
                        print("User data saved successfully")
                        UserDefaults.standard.set(id, forKey: "userId")
                    }
                }
            }
        }
    }
    
    // Example for manual data saving (orange login)
    func saveUserData(userName: String) {
        print("Saving user data with username: \(userName)")
        let usersCollection = Firestore.firestore().collection("users")
        let userId = "Am5Jsa1tA0IpyXMLuilm"
        
        usersCollection.whereField("userName", isEqualTo: userName).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Query failed: \(error.localizedDescription)")
                return
            }
            
            if let snapshot = querySnapshot, !snapshot.isEmpty {
                print("Username already exists, updating UserDefaults.")
                UserDefaults.standard.set(userName, forKey: "userName")
                UserDefaults.standard.set(userId, forKey: "userId")
                UserDefaults.standard.set("@900623", forKey: "email")
                print("Data saved to UserDefaults.")
            } else {
                print("Username does not exist, creating new user data in Firestore.")
                let newDocument = usersCollection.document(userId)
                let data = ["id": userId, "userName": userName, "email": "@900623"]
                
                newDocument.setData(data) { error in
                    if let error = error {
                        print("Error uploading data: \(error.localizedDescription)")
                    } else {
                        UserDefaults.standard.set(userName, forKey: "userName")
                        UserDefaults.standard.set(userId, forKey: "userId")
                        UserDefaults.standard.set("@900623", forKey: "email")
                        print("Data uploaded successfully and saved to UserDefaults.")
                    }
                }
            }
        }
    }
    
    func saveUserData2(userName: String) {
        print("Saving user data with username: \(userName)")
        let usersCollection = Firestore.firestore().collection("users")
        let userId = "UItPd5mGpUcpxQc2nGyy"
        
        usersCollection.whereField("userName", isEqualTo: userName).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Query failed: \(error.localizedDescription)")
                return
            }
            
            if let snapshot = querySnapshot, !snapshot.isEmpty {
                print("Username already exists, updating UserDefaults.")
                UserDefaults.standard.set(userName, forKey: "userName")
                UserDefaults.standard.set(userId, forKey: "userId")
                UserDefaults.standard.set("@900516", forKey: "email")
                print("Data saved to UserDefaults.")
            } else {
                print("Username does not exist, creating new user data in Firestore.")
                let newDocument = usersCollection.document(userId)
                let data = ["id": userId, "userName": userName, "email": "@900516"]
                
                newDocument.setData(data) { error in
                    if let error = error {
                        print("Error uploading data: \(error.localizedDescription)")
                    } else {
                        UserDefaults.standard.set(userName, forKey: "userName")
                        UserDefaults.standard.set(userId, forKey: "userId")
                        UserDefaults.standard.set("@900516", forKey: "email")
                        print("Data uploaded successfully and saved to UserDefaults.")
                    }
                }
            }
        }
    }
}

extension LoginViewController: ASAuthorizationControllerDelegate {
    
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("Authorization process completed.")
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            print("AppleID Credential received.")
            
            // 不需要使用 guard let，直接使用 appleIDCredential.user
            let userIdentifier = appleIDCredential.user
            print("User Identifier: \(userIdentifier)")
            
            UserDefaults.standard.set(userIdentifier, forKey: "userId")
            
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            // 驗證資料是否齊全
            guard let authorizationCode = appleIDCredential.authorizationCode,
                  let identityToken = appleIDCredential.identityToken else {
                print("Missing authorizationCode or identityToken.")
                return
            }
            
            let authorizationCodeString = String(data: authorizationCode, encoding: .utf8)
            let identityTokenString = String(data: identityToken, encoding: .utf8)
            
            // 儲存資料到 Firestore
            self.saveUserDataToFirestoreWithApple(id: userIdentifier, fullName: fullName, email: email, authorizationCode: authorizationCodeString, identityToken: identityTokenString)
            
            DispatchQueue.main.async {
                let tabBarController = TabBarController()
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController = tabBarController
                    window.makeKeyAndVisible()
                }
            }
            
        default:
            print("Unknown credential type.")
        }
    }
    
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Authorization failed with error: \(error.localizedDescription)")
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }
}
