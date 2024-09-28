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
    
    let imageView = UIImageView()
    let templateImageView = UIImageView()
    let uploadButton = UIButton(type: .system)
    var lastScale: CGFloat = 1.0
    var transparentArea: CGRect!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        tabBarController?.tabBar.isHidden = true
        
        // 设置模板图片
        view.addSubview(templateImageView)
        templateImageView.image = UIImage(named: "transparent_image")  // 模板图片名称
        templateImageView.contentMode = .scaleAspectFit
        templateImageView.isUserInteractionEnabled = false
        templateImageView.snp.makeConstraints { make in
            make.top.bottom.centerX.equalTo(view)
        }
        
        // 初始化用户图片视图
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true  // 启用用户交互
        view.insertSubview(imageView, belowSubview: templateImageView)  // 将图片视图置于模板下面
        
        // 设置上传照片按钮
        setupUploadButton()
        
        // 添加平移和缩放手势
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        imageView.addGestureRecognizer(panGesture)
        imageView.addGestureRecognizer(pinchGesture)
        
        // 添加保存和分享按钮
        setupSaveAndShareButtons()
        
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 定义透明区域（需要根据实际模板图片进行调整）
        defineTransparentArea()
        if imageView.image != nil {
            resetImageViewPositionAndSize()
        }
        
    }
    
    
    func defineTransparentArea() {
        // 假设透明区域位于模板的中心，占据模板的 80% 的宽度和高度
        let templateFrame = templateImageView.frame
        let width = templateFrame.width * 0.8
        let height = templateFrame.height * 0.8
        let xCoordinate = templateFrame.origin.x + (templateFrame.width - width) / 2
        let yCoordinate = templateFrame.origin.y + (templateFrame.height - height) / 2
        transparentArea = CGRect(x: xCoordinate, y: yCoordinate, width: width, height: height)
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
        // 将 imageView 的 frame 设置为 transparentArea
        imageView.frame = transparentArea
        imageView.transform = .identity  // 重置缩放和位移
        lastScale = 1.0  // 重置缩放因子
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
        adjustImageViewToCoverTransparentArea()
        adjustImageViewToScreenEdges()
    }
    
    // 处理缩放手势
    @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            let scale = gesture.scale
            imageView.transform = imageView.transform.scaledBy(x: scale, y: scale)
            gesture.scale = 1.0  // 重置缩放比例
        }
        
        adjustImageViewToCoverTransparentArea()
        adjustImageViewToScreenEdges()
    }
    
    func adjustImageViewToCoverTransparentArea() {
        guard let transparentArea = transparentArea else { return }
        
        let imageViewFrame = imageView.convert(imageView.bounds, to: view)
        
        if imageViewFrame.contains(transparentArea) {
            
        } else {
            
            var adjustedTransform = imageView.transform
            
            let scaleX = transparentArea.width / imageViewFrame.width
            let scaleY = transparentArea.height / imageViewFrame.height
            let requiredScale = max(scaleX, scaleY)
            
            adjustedTransform = adjustedTransform.scaledBy(x: requiredScale, y: requiredScale)
            
            imageView.transform = adjustedTransform
            
            let newImageViewFrame = imageView.convert(imageView.bounds, to: view)
            
            var translationX: CGFloat = 0
            var translationY: CGFloat = 0
            
            if newImageViewFrame.minX > transparentArea.minX {
                translationX = transparentArea.minX - newImageViewFrame.minX
            } else if newImageViewFrame.maxX < transparentArea.maxX {
                translationX = transparentArea.maxX - newImageViewFrame.maxX
            }
            
            if newImageViewFrame.minY > transparentArea.minY {
                translationY = transparentArea.minY - newImageViewFrame.minY
            } else if newImageViewFrame.maxY < transparentArea.maxY {
                translationY = transparentArea.maxY - newImageViewFrame.maxY
            }
            
            adjustedTransform = imageView.transform.translatedBy(x: translationX, y: translationY)
            imageView.transform = adjustedTransform
        }
    }
    
    func adjustImageViewToScreenEdges() {
        
        let imageViewFrame = imageView.convert(imageView.bounds, to: view)
        
        let imageLeft = imageViewFrame.minX
        let imageRight = view.bounds.width - imageViewFrame.maxX
        let imageTop = imageViewFrame.minY
        let imageBottom = view.bounds.height - imageViewFrame.maxY
        
        let leftMargin = transparentArea.minX
        let rightMargin = view.bounds.width - transparentArea.maxX
        let topMargin = transparentArea.minY
        let bottomMargin = view.bounds.height - transparentArea.maxY
        
        var translationX: CGFloat = 0
        var translationY: CGFloat = 0
        
        if imageLeft > leftMargin {
            translationX = leftMargin - imageLeft
        }
        if imageRight > rightMargin {
            translationX += (view.bounds.width - rightMargin - imageViewFrame.maxX)
        }
        if imageTop > topMargin {
            translationY = topMargin - imageTop
        }
        if imageBottom > bottomMargin {
            translationY += (view.bounds.height - bottomMargin - imageViewFrame.maxY)
        }
        
        imageView.transform = imageView.transform.translatedBy(x: translationX, y: translationY)
    }
    
    @objc func saveToPhotoAlbum() {
        let combinedImage = generateCombinedImage()
        
        UIImageWriteToSavedPhotosAlbum(combinedImage, self, #selector(imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func imageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            
            print("保存失敗: \(error.localizedDescription)")
        } else {
            
            print("保存成功")
        }
    }
    
    func saveImageWithMask() {
        let renderer = UIGraphicsImageRenderer(size: templateImageView.bounds.size)
        
        let renderedImage = renderer.image { context in
            
            UIColor.white.setFill()
            context.fill(templateImageView.bounds)
            
            let scaledRect = imageView.frame
            imageView.image?.draw(in: scaledRect)
            
            templateImageView.image?.draw(in: templateImageView.bounds, blendMode: .normal, alpha: 1.0)
        }
        
        UIImageWriteToSavedPhotosAlbum(renderedImage, nil, nil, nil)
        
        let shareButton = UIButton(type: .system)
        shareButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        shareButton.addTarget(self, action: #selector(shareToInstagram), for: .touchUpInside)
        view.addSubview(shareButton)
    }
    
    @objc func shareToInstagram() {
        
        guard let instagramURL = URL(string: "instagram-stories://share") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(instagramURL) {
            let renderer = UIGraphicsImageRenderer(size: templateImageView.bounds.size)
            let renderedImage = renderer.image { context in
                UIColor.white.setFill()
                context.fill(templateImageView.bounds)
                let scaledRect = imageView.frame
                imageView.image?.draw(in: scaledRect)
                templateImageView.image?.draw(in: templateImageView.bounds, blendMode: .normal, alpha: 1.0)
            }
            
            let pasteboardItems: [String: Any] = [
                "com.instagram.sharedSticker.backgroundImage": renderedImage.pngData() ?? Data(),
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
