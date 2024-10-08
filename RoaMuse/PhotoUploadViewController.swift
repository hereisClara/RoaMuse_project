import UIKit
import SnapKit
import Photos

class PhotoUploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let imageView = UIImageView()
    let templateImageView = UIImageView()
    
    let shareButton = UIButton(type: .system)
    let uploadButton = UIButton(type: .system)
    let saveButton = UIButton(type: .system)
    let buttonStackView = UIStackView()
    let cameraButton = UIButton(type: .system)
    var lastScale: CGFloat = 1.0
    var initialCenter: CGPoint = .zero
    var transparentArea: CGRect!
    
    var imageViewConstraints: [Constraint] = [] // 保存 ImageView 的約束
    let minWidthScale: CGFloat = UIScreen.main.bounds.width
    let minHeightScale: CGFloat = UIScreen.main.bounds.height
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
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
        setupImageViewConstraints()
        setupButtons()
        setupButtonStackView()
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        imageView.addGestureRecognizer(panGesture)
        imageView.addGestureRecognizer(pinchGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 隱藏 TabBar
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        defineTransparentArea()
        if imageView.image != nil {
            resetImageViewPositionAndSize()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    func defineTransparentArea() {
        let templateFrame = templateImageView.frame
        let width = templateFrame.width * 0.8
        let height = templateFrame.height * 0.8
        let xCoordinate = templateFrame.origin.x + (templateFrame.width - width) / 2
        let yCoordinate = templateFrame.origin.y + (templateFrame.height - height) / 2
        transparentArea = CGRect(x: xCoordinate, y: yCoordinate, width: width, height: height)
    }
    
    func setupButtons() {
            // 分享按鈕
            shareButton.setImage(UIImage(systemName: "square.and.arrow.up.circle.fill"), for: .normal)
            shareButton.tintColor = .deepBlue
            shareButton.addTarget(self, action: #selector(shareAction), for: .touchUpInside)

            // 上傳圖片按鈕
            uploadButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
            uploadButton.tintColor = .deepBlue
            uploadButton.addTarget(self, action: #selector(uploadPhoto), for: .touchUpInside)

            // 保存圖片按鈕
            saveButton.setImage(UIImage(systemName: "arrow.down.circle.fill"), for: .normal)
            saveButton.tintColor = .accent
            saveButton.addTarget(self, action: #selector(saveToPhotoAlbum), for: .touchUpInside)
        
        cameraButton.setImage(UIImage(systemName: "camera.circle.fill"), for: .normal)
        cameraButton.tintColor = .deepBlue
        cameraButton.addTarget(self, action: #selector(openCamera), for: .touchUpInside)
        }

    func setupButtonStackView() {
        // 添加半透明的白色背景 View
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.8) // 设置半透明白色
        backgroundView.layer.cornerRadius = 40 // 圆角为宽度的一半
        backgroundView.layer.masksToBounds = true
        view.addSubview(backgroundView)
        
        // 设置背景 View 的约束
        backgroundView.snp.makeConstraints { make in
            make.trailing.equalTo(view).offset(-20)
            make.bottom.equalTo(view).offset(-50)
            make.width.equalTo(80) // 宽度与按钮相同
            make.height.equalTo(280) // 根据按钮数量设置高度
        }
        
        // 继续设置垂直的 StackView 来排列按钮
        buttonStackView.axis = .vertical
        buttonStackView.alignment = .fill
        buttonStackView.distribution = .equalSpacing
        buttonStackView.spacing = 20

        // 添加按钮到 StackView
        buttonStackView.addArrangedSubview(shareButton)
        buttonStackView.addArrangedSubview(uploadButton)
        buttonStackView.addArrangedSubview(cameraButton) // 新增的相机按钮
        buttonStackView.addArrangedSubview(saveButton)
        
        view.addSubview(buttonStackView)

        // 设置 StackView 的约束，使其位于背景 View 内
        buttonStackView.snp.makeConstraints { make in
            make.edges.equalTo(backgroundView).inset(10) // 让按钮距离背景 View 内边距 10 点
        }

        // 设置每个按钮的大小
        [shareButton, uploadButton, cameraButton, saveButton].forEach { button in
            button.snp.makeConstraints { make in
                make.width.height.equalTo(50)
            }
        }
    }

    @objc func openCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }


    @objc func uploadPhoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @objc func shareAction() {
        // 創建 AlertSheet
        let alertSheet = UIAlertController(title: "分享", message: "選擇分享方式", preferredStyle: .actionSheet)
        
        // 添加分享到外部選項
        let shareToExternalAction = UIAlertAction(title: "分享到外部", style: .default) { [weak self] _ in
            self?.shareToExternal()
        }
        
        // 添加分享到日記選項
        let shareToDiaryAction = UIAlertAction(title: "分享到日記", style: .default) { [weak self] _ in
            self?.shareToDiary()
        }
        
        // 添加取消選項
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
        // 將選項添加到 AlertSheet
        alertSheet.addAction(shareToExternalAction)
        alertSheet.addAction(shareToDiaryAction)
        alertSheet.addAction(cancelAction)
        
        // 顯示選項表
        present(alertSheet, animated: true, completion: nil)
    }

    // 分享到外部的方法
    func shareToExternal() {
        // 分享操作，使用 captureScreenshotExcludingViews 捕捉當前畫面
        if let image = captureScreenshotExcludingViews([buttonStackView]) {
            let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }

    // 分享到日記的方法
    func shareToDiary() {
        // 將當前圖片傳遞到 PostViewController
        guard let combinedImage = captureScreenshotExcludingViews([buttonStackView]) else {
                print("无法捕捉合成后的图片")
                return
            }
        let postVC = PostViewController()
        
        postVC.sharedImage = combinedImage

        self.navigationController?.pushViewController(postVC, animated: true)
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
        
        let screenHeight = UIScreen.main.bounds.height
        let imageAspectRatio = image.size.width / image.size.height

        // 設定 imageView 的高度等於螢幕高度
        let newHeight = screenHeight
        let newWidth = newHeight * imageAspectRatio

        updateImageViewConstraints(width: newWidth, height: newHeight)
    }

    func setupImageViewConstraints() {
        imageViewConstraints = []
        imageView.snp.makeConstraints { make in
            imageViewConstraints.append(make.width.equalTo(templateImageView).constraint)
            imageViewConstraints.append(make.height.equalTo(templateImageView).constraint)
            imageViewConstraints.append(make.center.equalTo(templateImageView).constraint)
        }
    }

    // 更新 imageView 的约束
    func updateImageViewConstraints(width: CGFloat, height: CGFloat) {
        imageView.snp.remakeConstraints { make in
            make.width.equalTo(width)
            make.height.equalTo(height)
            make.center.equalTo(templateImageView)
        }
        view.layoutIfNeeded()
    }

    @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        let minWidth = UIScreen.main.bounds.width
        let minHeight = UIScreen.main.bounds.height
        
        if gesture.state == .began || gesture.state == .changed {
            let newWidth = imageView.frame.width * gesture.scale
            let newHeight = imageView.frame.height * gesture.scale

            if newWidth >= minWidth && newHeight >= minHeight {
                view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            } else {
                let scaleWidth = minWidth / imageView.frame.width
                let scaleHeight = minHeight / imageView.frame.height
                let scaleFactor = max(scaleWidth, scaleHeight)

                view.transform = view.transform.scaledBy(x: scaleFactor, y: scaleFactor)
            }
            
            gesture.scale = 1.0
        }

        ensureImageViewWithinBounds()
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

        if gesture.state == .ended || gesture.state == .changed {
            ensureImageViewWithinBounds()
        }
    }

    // 确保 imageView 不超出 transparentArea 的范围
    func ensureImageViewWithinBounds() {
        let imageFrame = imageView.frame
        let superviewBounds = view.bounds

        var newCenter = imageView.center

        // 確保圖片不超出左右邊界
        if imageFrame.minX > 0 {
            newCenter.x = imageView.frame.width / 2
        } else if imageFrame.maxX < superviewBounds.width {
            newCenter.x = superviewBounds.width - imageView.frame.width / 2
        }

        // 確保圖片不超出上下邊界
        if imageFrame.minY > 0 {
            newCenter.y = imageView.frame.height / 2
        } else if imageFrame.maxY < superviewBounds.height {
            newCenter.y = superviewBounds.height - imageView.frame.height / 2
        }

        imageView.center = newCenter
    }

    func captureScreenshotExcludingViews(_ excludedViews: [UIView]) -> UIImage? {
        
        excludedViews.forEach { $0.isHidden = true }

        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let screenshot = renderer.image { context in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }

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
            print("保存失败: \(error.localizedDescription)")
        } else {
            print("保存成功")
        }
    }
}
