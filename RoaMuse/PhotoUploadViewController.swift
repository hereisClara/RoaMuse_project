//
//  PhotoUploadViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/27.
//

import UIKit
import SnapKit
import Photos

class PhotoUploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let imageView = UIImageView()           // 用戶上傳的圖片視圖
    let templateImageView = UIImageView()   // 模板圖片視圖
    let uploadButton = UIButton(type: .system)  // 上傳照片按鈕
    var lastScale: CGFloat = 1.0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // 設置模板圖片
        view.addSubview(templateImageView)
        templateImageView.image = UIImage(named: "transparent_image")  // 模板圖片名稱
        templateImageView.contentMode = .scaleAspectFit
        templateImageView.isUserInteractionEnabled = false
        templateImageView.snp.makeConstraints { make in
            make.top.bottom.equalTo(view)
            make.centerX.equalTo(view)
        }

        // 初始化用戶圖片視圖
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true  // 啟用用戶交互
        view.insertSubview(imageView, belowSubview: templateImageView)  // 將圖片視圖置於模板下面

        // 設置上傳照片按鈕
        setupUploadButton()

        // 添加平移和縮放手勢
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        imageView.addGestureRecognizer(panGesture)
        imageView.addGestureRecognizer(pinchGesture)

        // 添加保存和分享按鈕
        setupSaveAndShareButtons()
    }

    func setupUploadButton() {
        // 設置按鈕樣式和圖標
        uploadButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        uploadButton.tintColor = .systemBlue
        uploadButton.addTarget(self, action: #selector(uploadPhoto), for: .touchUpInside)

        // 將按鈕添加到視圖
        view.addSubview(uploadButton)

        // 設置按鈕的佈局，位於遮罩透明區域下方，並且水平居中
        uploadButton.snp.makeConstraints { make in
            make.top.equalTo(templateImageView.snp.bottom).offset(-150)  // 位於模板圖片下方
            make.centerX.equalTo(view)
            make.width.height.equalTo(50)  // 設置圖標大小
        }
    }

    // 設置保存和分享按鈕
    func setupSaveAndShareButtons() {
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("保存到相簿", for: .normal)
        saveButton.addTarget(self, action: #selector(saveToPhotoAlbum), for: .touchUpInside)
        view.addSubview(saveButton)

        let shareButton = UIButton(type: .system)
        shareButton.setTitle("分享到 IG 限時動態", for: .normal)
        shareButton.addTarget(self, action: #selector(shareToInstagram), for: .touchUpInside)
        view.addSubview(shareButton)

        // 佈局保存按鈕
        saveButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.snp.bottom).offset(-100)
            make.leading.equalTo(view.snp.leading).offset(5)
            make.width.equalTo(150)
            make.height.equalTo(50)
        }

        // 佈局分享按鈕
        shareButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.snp.bottom).offset(-100)
            make.trailing.equalTo(view.snp.trailing).offset(-5)
            make.width.equalTo(200)
            make.height.equalTo(50)
        }
    }

    // 用戶點擊按鈕後上傳照片
    @objc func uploadPhoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }

    // 用戶選擇照片後回調
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            dismiss(animated: true, completion: {
                // 設置選擇的圖片
                self.imageView.image = selectedImage
                self.resetImageViewPositionAndSize()
            })
        }
    }

    // 重置圖片的大小和位置，使其適應屏幕
    func resetImageViewPositionAndSize() {
        imageView.frame = templateImageView.frame  // 使圖片大小和模板一致
        imageView.transform = .identity  // 重置縮放和位移
        lastScale = 1.0  // 重置縮放因子
    }

    // 處理取消選擇照片的情況
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    // 處理拖動手勢
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        if gesture.state == .began || gesture.state == .changed {
            imageView.center = CGPoint(x: imageView.center.x + translation.x, y: imageView.center.y + translation.y)
            gesture.setTranslation(.zero, in: view)  // 重置平移量
        }
    }

    // 處理縮放手勢
    @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            let scale = gesture.scale
            imageView.transform = imageView.transform.scaledBy(x: scale, y: scale)
            gesture.scale = 1.0  // 重置縮放比例
        }
    }

    // 保存圖片到本地相簿
    @objc func saveToPhotoAlbum() {
        // 將模板和用戶上傳的圖片合成
        let combinedImage = generateCombinedImage()
        
        // 保存到相簿
        UIImageWriteToSavedPhotosAlbum(combinedImage, self, #selector(imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    // 保存圖片完成後的回調
    @objc func imageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // 保存失敗
            print("保存失敗: \(error.localizedDescription)")
        } else {
            // 保存成功
            print("保存成功")
        }
    }

    @objc func shareToInstagram() {
        guard let instagramURL = URL(string: "instagram-stories://share") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(instagramURL) {
            let combinedImage = generateCombinedImage()
            
            let pasteboardItems: [String: Any] = [
                "com.instagram.sharedSticker.backgroundImage": combinedImage.pngData() ?? Data(),
            ]
            UIPasteboard.general.setItems([pasteboardItems], options: [:])
            UIApplication.shared.open(instagramURL)
        }
    }

    // 將模板和用戶上傳的圖片合成
    func generateCombinedImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(templateImageView.bounds.size, false, 0.0)

        // 先繪製用戶上傳的圖片
        imageView.image?.draw(in: imageView.frame)
        
        // 然後在上面繪製模板圖片，模板會在圖片上方
        templateImageView.image?.draw(in: templateImageView.bounds)

        // 獲取合成後的圖片
        let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return combinedImage ?? UIImage()
    }
}
