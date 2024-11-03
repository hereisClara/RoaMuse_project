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
//        view.backgroundColor = .black
        let waveView = CustomMaskWaveView(frame: view.bounds)
        view.addSubview(waveView)
        let backgroundImage = UIImage(named: "backgroundImage")
        let backgroundImageView = UIImageView(frame: UIScreen.main.bounds)
        backgroundImageView.image = backgroundImage
        backgroundImageView.contentMode = .scaleAspectFill
        checkAppleSignInStatus()
        view.insertSubview(backgroundImageView, at: 0)
        checkEULAAgreement()
        setupUI()
        configureAppleSignInButton()
    }
    
    func checkAppleSignInStatus() {
        if let appleUserIdentifier = UserDefaults.standard.string(forKey: "userId") {
            verifyAppleSignIn(appleUserIdentifier: appleUserIdentifier)
        } else {
            print("No previous Apple sign-in found.")
        }
    }

    func verifyAppleSignIn(appleUserIdentifier: String) {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: appleUserIdentifier) { (credentialState, error) in
            switch credentialState {
            case .authorized:
                print("User is still signed in with Apple ID.")
                DispatchQueue.main.async {
                    self.navigateToHome()
                }
            case .revoked:
                print("Apple ID credentials revoked.")
                self.showLoginUI()
            case .notFound:
                print("Apple ID credentials not found.")
                self.showLoginUI()
            default:
                break
            }
        }
    }

    func navigateToHome() {
        let tabBarController = TabBarController()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        }
    }

    func showLoginUI() {
        DispatchQueue.main.async {
            print("Showing login UI.")
            self.appleSignInButton.isHidden = false
        }
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
        let isEULAAccepted = UserDefaults.standard.bool(forKey: "EULAAccepted")
        if !isEULAAccepted {
            showEULAAlert()
        }
    }

    func showEULAAlert() {
        let alertController = UIAlertController(title: "End User License Agreement (EULA)",
                                                message: "By using this app, you agree to our terms and conditions. We have a zero-tolerance policy for objectionable content or abusive behavior.",
                                                preferredStyle: .alert)

        let acceptAction = UIAlertAction(title: "Accept", style: .default) { _ in
            UserDefaults.standard.set(true, forKey: "EULAAccepted")
            print("User has accepted the EULA.")
        }
        
        let declineAction = UIAlertAction(title: "Decline", style: .destructive) { _ in
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
        
        var userData: [String: Any] = [
            "id": id,
            "identityToken": identityToken ?? "",
            "authorizationCode": authorizationCode ?? ""
        ]
        
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
        
        usersCollection.document(id).getDocument { documentSnapshot, error in
            if let document = documentSnapshot, document.exists {
                print("User already exists, not updating userName or email.")
            } else {
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
            
            let userIdentifier = appleIDCredential.user
            print("User Identifier: \(userIdentifier)")
            
            UserDefaults.standard.set(userIdentifier, forKey: "userId")
            
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            guard let authorizationCode = appleIDCredential.authorizationCode,
                  let identityToken = appleIDCredential.identityToken else {
                print("Missing authorizationCode or identityToken.")
                return
            }
            
            let authorizationCodeString = String(data: authorizationCode, encoding: .utf8)
            let identityTokenString = String(data: identityToken, encoding: .utf8)
            
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
