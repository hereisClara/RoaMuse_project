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
    let saveButton = UIButton(type: .system)
    let shareButton = UIButton(type: .system)
    
    var lastScale: CGFloat = 1.0
    var initialCenter: CGPoint = .zero
    var transparentArea: CGRect!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        tabBarController?.tabBar.isHidden = true
        
        view.addSubview(templateImageView)
        templateImageView.image = UIImage(named: "transparent_image")  // 模板图片名称
        templateImageView.contentMode = .scaleAspectFit
        templateImageView.isUserInteractionEnabled = false
        templateImageView.snp.makeConstraints { make in
            make.top.bottom.centerX.equalTo(view)
        }
        
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true  // 启用用户交互
        view.insertSubview(imageView, belowSubview: templateImageView)  // 将图片视图置于模板下面
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(templateImageView)
            make.center.equalTo(templateImageView)
        }
        
        setupUploadButton()
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        imageView.addGestureRecognizer(panGesture)
        imageView.addGestureRecognizer(pinchGesture)
        
        setupSaveAndShareButtons()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        defineTransparentArea()
        if imageView.image != nil {
            resetImageViewPositionAndSize()
        }
    }
    
    func defineTransparentArea() {
        let templateFrame = templateImageView.frame
        let width = templateFrame.width * 0.8
        let height = templateFrame.height * 0.8
        let xCoordinate = templateFrame.origin.x + (templateFrame.width - width) / 2
        let yCoordinate = templateFrame.origin.y + (templateFrame.height - height) / 2
        transparentArea = CGRect(x: xCoordinate, y: yCoordinate, width: width, height: height)
    }
    
    func setupUploadButton() {
        uploadButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        uploadButton.tintColor = .systemBlue
        uploadButton.addTarget(self, action: #selector(uploadPhoto), for: .touchUpInside)
        
        view.addSubview(uploadButton)
        
        uploadButton.snp.makeConstraints { make in
            make.top.equalTo(templateImageView.snp.bottom).offset(-150)
            make.centerX.equalTo(view)
            make.width.height.equalTo(50)
        }
    }
    
    func setupSaveAndShareButtons() {
        saveButton.setTitle("保存到相簿", for: .normal)
        saveButton.addTarget(self, action: #selector(saveToPhotoAlbum), for: .touchUpInside)
        view.addSubview(saveButton)
        
        shareButton.setTitle("分享到 IG", for: .normal)
        view.addSubview(shareButton)
        
        saveButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.snp.bottom).offset(-100)
            make.leading.equalTo(view.snp.leading).offset(5)
            make.width.equalTo(150)
            make.height.equalTo(50)
        }
        
        shareButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.snp.bottom).offset(-100)
            make.trailing.equalTo(view.snp.trailing).offset(-5)
            make.width.equalTo(200)
            make.height.equalTo(50)
        }
    }
    
    @objc func uploadPhoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            dismiss(animated: true, completion: {
                self.imageView.image = selectedImage
                self.resetImageViewPositionAndSize()
            })
        }
    }
    
    func resetImageViewPositionAndSize() {
        guard let image = imageView.image else { return }
        
        let imageAspectRatio = image.size.width / image.size.height
        let transparentAreaAspectRatio = transparentArea.width / transparentArea.height
        
        var newWidth: CGFloat
        var newHeight: CGFloat
        
        if imageAspectRatio > transparentAreaAspectRatio {
            newWidth = transparentArea.width
            newHeight = newWidth / imageAspectRatio
        } else {
            newHeight = transparentArea.height
            newWidth = newHeight * imageAspectRatio
        }
        
        let xOffset = transparentArea.origin.x + (transparentArea.width - newWidth) / 2
        let yOffset = transparentArea.origin.y + (transparentArea.height - newHeight) / 2
        
        imageView.frame = CGRect(x: xOffset, y: yOffset, width: newWidth, height: newHeight)
        
        imageView.transform = .identity
        lastScale = 1.0
        initialCenter = imageView.center
    }

    func captureScreenshotExcludingViews(_ excludedViews: [UIView]) -> UIImage? {
        // 暫時隱藏排除的視圖
        excludedViews.forEach { $0.isHidden = true }
        
        // 截圖
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let screenshot = renderer.image { context in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        
        // 恢復視圖可見性
        excludedViews.forEach { $0.isHidden = false }
        
        return screenshot
    }

    @objc func saveToPhotoAlbum() {
        if let screenshot = captureScreenshotExcludingViews([uploadButton, saveButton, shareButton]) {
            UIImageWriteToSavedPhotosAlbum(screenshot, self, #selector(imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc func imageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("保存失敗: \(error.localizedDescription)")
        } else {
            print("保存成功")
        }
    }

    @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }

        if gesture.state == .began || gesture.state == .changed {
            view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1.0
        }
    }

    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        if gesture.state == .began {
            initialCenter = imageView.center
        }
        
        if gesture.state == .changed {
            let newCenter = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
            imageView.center = newCenter
        }
    }
}
