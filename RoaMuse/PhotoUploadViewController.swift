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
    
    @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }

        if gesture.state == .began || gesture.state == .changed {
            let currentScale = view.frame.size.width / view.bounds.size.width
            var newScale = currentScale * gesture.scale

            // 限制缩放范围，确保图片不会缩小到比透明区域更小
            let minScale = max(transparentArea.size.width / view.bounds.size.width, transparentArea.size.height / view.bounds.size.height)
            let maxScale: CGFloat = 3.0

            // 确保 newScale 在 minScale 和 maxScale 之间
            if newScale >= minScale && newScale <= maxScale {
                view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            }

            // 重置手势缩放比例
            gesture.scale = 1.0
        }

        // 在缩放完成时调整边界
        if gesture.state == .ended {
            adjustImageViewToCoverTransparentArea()
        }
    }

    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        if gesture.state == .began || gesture.state == .changed {
            imageView.center = CGPoint(x: imageView.center.x + translation.x, y: imageView.center.y + translation.y)
            gesture.setTranslation(.zero, in: view)
        }
        
        adjustImageViewToCoverTransparentArea()
    }

    func adjustImageViewToCoverTransparentArea() {
        guard let transparentArea = transparentArea else { return }
        
        let imageViewFrame = imageView.frame
        
        var translationX: CGFloat = 0
        var translationY: CGFloat = 0
        
        // 检查水平边界
        if imageViewFrame.minX > transparentArea.minX {
            translationX = transparentArea.minX - imageViewFrame.minX
        } else if imageViewFrame.maxX < transparentArea.maxX {
            translationX = transparentArea.maxX - imageViewFrame.maxX
        }
        
        // 检查垂直边界
        if imageViewFrame.minY > transparentArea.minY {
            translationY = transparentArea.minY - imageViewFrame.minY
        } else if imageViewFrame.maxY < transparentArea.maxY {
            translationY = transparentArea.maxY - imageViewFrame.maxY
        }
        
        imageView.transform = imageView.transform.translatedBy(x: translationX, y: translationY)
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
    
    func generateCombinedImage() -> UIImage {
        // 使用屏幕的 scale 来保持图片清晰度和正确比例
        UIGraphicsBeginImageContextWithOptions(templateImageView.bounds.size, false, UIScreen.main.scale)

        // 将 imageView 的 frame 转换到 templateImageView 的坐标系中
        let imageViewFrameInTemplate = imageView.convert(imageView.bounds, to: templateImageView)

        // 绘制用户上传的图片
        imageView.image?.draw(in: imageViewFrameInTemplate)

        // 绘制模板图片
        templateImageView.image?.draw(in: templateImageView.bounds)

        // 获取合成后的图片
        let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return combinedImage ?? UIImage()
    }

}
