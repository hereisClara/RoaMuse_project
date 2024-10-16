import UIKit
import SnapKit
import Photos
import CoreImage

class PhotoUploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var maskOpacityValue: Float = 1.0
    var brightnessValue: Float = 0.0
    var saturationValue: Float = 1.0
    var blurValue: Float = 1.0
    let stackViewBackgroundView = UIView()
    let imageView = UIImageView()
    let templateImageView = UIImageView()
    var selectedTrip: Trip?
    let shareButton = UIButton(type: .system)
    let uploadButton = UIButton(type: .system)
    let saveButton = UIButton(type: .system)
    let buttonStackView = UIStackView()
    let cameraButton = UIButton(type: .system)
    var lastScale: CGFloat = 1.0
    var initialCenter: CGPoint = .zero
    var transparentArea: CGRect!
    let sliderButton = UIButton(type: .system) // 新增的按钮
    let sliderBackgroundView = UIView()
    var slider = UISlider()
    var sliderLabel = UILabel()
    var imageViewConstraints: [Constraint] = [] // 保存 ImageView 的約束
    let minWidthScale: CGFloat = UIScreen.main.bounds.width
    let minHeightScale: CGFloat = UIScreen.main.bounds.height
    var backgroundView = UIView()
    var popupView = UIView()
    var context = CIContext()
    var currentCIImage: CIImage?
    var currentFilter: CIFilter?
    
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
        setupSliderButton()
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
//        self.tabBarController?.tabBar.isHidden = false
    }
    
    func defineTransparentArea() {
        let templateFrame = templateImageView.frame
        let width = templateFrame.width * 0.8
        let height = templateFrame.height * 0.8
        let xCoordinate = templateFrame.origin.x + (templateFrame.width - width) / 2
        let yCoordinate = templateFrame.origin.y + (templateFrame.height - height) / 2
        transparentArea = CGRect(x: xCoordinate, y: yCoordinate, width: width, height: height)
    }
    
    func setupSliderButton() {
        
        sliderButton.setImage(UIImage(systemName: "slider.horizontal.3"), for: .normal)
        sliderButton.tintColor = .white
        sliderButton.addTarget(self, action: #selector(sliderButtonTapped), for: .touchUpInside)
        sliderBackgroundView.addSubview(sliderButton)
        
        sliderButton.snp.makeConstraints { make in
            make.center.equalTo(sliderBackgroundView)
            make.width.height.equalTo(30)
        }
        
        sliderButton.addTarget(self, action: #selector(sliderButtonTapped), for: .touchUpInside)
    }
    
    func createSlider(label: String, min: Float, max: Float, defaultValue: Float, action: Selector) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        
        let titleLabel = UILabel()
        titleLabel.text = label
        titleLabel.textAlignment = .center
        stackView.addArrangedSubview(titleLabel)
        
        let slider = UISlider()
        slider.minimumValue = min
        slider.maximumValue = max
        slider.value = defaultValue  // 設置預設值
        slider.addTarget(self, action: action, for: .valueChanged)
        stackView.addArrangedSubview(slider)
        
        return stackView
    }

    @objc func sliderButtonTapped() {
        
        guard let window = UIApplication.shared.keyWindow else { return }
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backgroundView.frame = window.bounds
        window.addSubview(backgroundView)
        
        let popupView = UIView()
        popupView.backgroundColor = .white
        popupView.layer.cornerRadius = 15
        popupView.layer.masksToBounds = true
        backgroundView.addSubview(popupView)
        
        popupView.snp.makeConstraints { make in
            make.center.equalTo(backgroundView)
            make.width.equalTo(window).multipliedBy(0.9)
            make.height.equalTo(400)
        }
         
        let maskOpacitySlider = createSlider(label: "遮罩透明度", min: 0.0, max: 1.0, defaultValue: maskOpacityValue, action: #selector(adjustMaskOpacity(_:)))
        popupView.addSubview(maskOpacitySlider)
        maskOpacitySlider.snp.makeConstraints { make in
            make.top.equalTo(popupView).offset(20)
            make.centerX.equalTo(popupView)
            make.width.equalTo(popupView).multipliedBy(0.8)
        }
        
        let brightnessSlider = createSlider(label: "亮度", min: -0.3, max: 0.3, defaultValue: brightnessValue, action: #selector(adjustBrightness(_:)))
        let saturationSlider = createSlider(label: "飽和度", min: 0.5, max: 1.5, defaultValue: saturationValue, action: #selector(adjustSaturation(_:)))
        let blurSlider = createSlider(label: "模糊", min: 0.0, max: 5.0, defaultValue: blurValue, action: #selector(adjustBlur(_:)))

        popupView.addSubview(brightnessSlider)
        brightnessSlider.snp.makeConstraints { make in
            make.top.equalTo(maskOpacitySlider.snp.bottom).offset(20)
            make.centerX.equalTo(popupView)
            make.width.equalTo(popupView).multipliedBy(0.8)
        }
        
        // 添加滑块：饱和度
        popupView.addSubview(saturationSlider)
        saturationSlider.snp.makeConstraints { make in
            make.top.equalTo(brightnessSlider.snp.bottom).offset(20)
            make.centerX.equalTo(popupView)
            make.width.equalTo(popupView).multipliedBy(0.8)
        }
        
        // 添加滑块：模糊程度
        popupView.addSubview(blurSlider)
        blurSlider.snp.makeConstraints { make in
            make.top.equalTo(saturationSlider.snp.bottom).offset(20)
            make.centerX.equalTo(popupView)
            make.width.equalTo(popupView).multipliedBy(0.8)
        }
        
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("关闭", for: .normal)
        closeButton.tintColor = .systemBlue
        closeButton.addTarget(self, action: #selector(dismissPopup), for: .touchUpInside)
        popupView.addSubview(closeButton)
        
        closeButton.snp.makeConstraints { make in
            make.bottom.equalTo(popupView.snp.bottom).offset(-20)
            make.centerX.equalTo(popupView)
        }
        
        // 保存引用用于关闭弹窗时使用
        self.backgroundView = backgroundView
        self.popupView = popupView
//        self.sliderLabel = sliderLabel
//        self.slider = slider
    }
    
    // 调整遮罩透明度
    @objc func adjustMaskOpacity(_ sender: UISlider) {
        let alpha = CGFloat(sender.value)
        maskOpacityValue = sender.value
        templateImageView.alpha = alpha
    }
    
    // 调整亮度
    @objc func adjustBrightness(_ sender: UISlider) {
        // 限制为 2% 的步进
        let step: Float = 0.04
        let roundedValue = round(sender.value / step) * step
        sender.value = roundedValue
        brightnessValue = roundedValue
        applyFilter(name: "CIColorControls", parameters: [kCIInputBrightnessKey: roundedValue])
    }

    @objc func adjustSaturation(_ sender: UISlider) {
        // 限制为 2% 的步进
        let step: Float = 0.04
        let roundedValue = round(sender.value / step) * step
        sender.value = roundedValue
        saturationValue = roundedValue
        applyFilter(name: "CIColorControls", parameters: [kCIInputSaturationKey: roundedValue])
    }

    @objc func adjustBlur(_ sender: UISlider) {
        // 限制为 2% 的步进
        let step: Float = 0.04
        let roundedValue = round(sender.value / step) * step
        sender.value = roundedValue
        blurValue = roundedValue
        applyFilter(name: "CIGaussianBlur", parameters: [kCIInputRadiusKey: roundedValue])
    }

    @objc func sliderValueChanged(_ sender: UISlider) {
        // 限制为 2% 的步进
        let step: Float = 0.04
        let roundedValue = round(sender.value / step) * step
        sender.value = roundedValue
        adjustMaskOpacity(sender)
    }

    func applyFilter(name: String, parameters: [String: Any]) {
        guard let ciImage = currentCIImage else {
            print("無法獲取 CIImage")
            return
        }

        // 如果過去的濾鏡是同一種濾鏡，直接重用
        if currentFilter?.name != name {
            currentFilter = CIFilter(name: name)
            currentFilter?.setDefaults()
        }

        guard let filter = currentFilter else {
            print("無法創建 CIFilter")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            
            parameters.forEach { key, value in
                filter.setValue(value, forKey: key)
            }
            
            if let outputImage = filter.outputImage,
               let cgImage = self.context.createCGImage(outputImage, from: outputImage.extent) {
                
                DispatchQueue.main.async {
                    self.imageView.image = UIImage(cgImage: cgImage)
                }
            } else {
                print("濾鏡應用失敗")
            }
        }
    }
    
    @objc func dismissPopup() {
        backgroundView.removeFromSuperview()
    }
    
    func setupButtons() {
        // 分享按鈕
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up.fill"), for: .normal)
        shareButton.tintColor = .deepBlue
        shareButton.addTarget(self, action: #selector(shareAction), for: .touchUpInside)
        
        // 上傳圖片按鈕
        uploadButton.setImage(UIImage(systemName: "photo.badge.plus.fill"), for: .normal)
        uploadButton.tintColor = .deepBlue
        uploadButton.addTarget(self, action: #selector(uploadPhoto), for: .touchUpInside)
        
        // 保存圖片按鈕
        saveButton.setImage(UIImage(systemName: "tray.and.arrow.down.fill"), for: .normal)
        saveButton.tintColor = .accent
        saveButton.addTarget(self, action: #selector(saveToPhotoAlbum), for: .touchUpInside)
        
        cameraButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        cameraButton.tintColor = .deepBlue
        cameraButton.addTarget(self, action: #selector(openCamera), for: .touchUpInside)
    }
    
    func setupButtonStackView() {
        
        stackViewBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.8) // 设置半透明白色
        stackViewBackgroundView.layer.cornerRadius = 25 // 圆角为宽度的一半
        stackViewBackgroundView.layer.masksToBounds = true
        view.addSubview(stackViewBackgroundView)
        
        // 设置背景 View 的约束
        stackViewBackgroundView.snp.makeConstraints { make in
            make.trailing.equalTo(view).offset(-20)
            make.bottom.equalTo(view).offset(-50)
            make.width.equalTo(50) // 宽度与按钮相同
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
            make.edges.equalTo(stackViewBackgroundView).inset(10) // 让按钮距离背景 View 内边距 10 点
        }
        
        // 设置每个按钮的大小
        [shareButton, uploadButton, cameraButton, saveButton].forEach { button in
            button.snp.makeConstraints { make in
                make.width.height.equalTo(50)
            }
        }
        
        let visibleButtons = [shareButton, uploadButton, cameraButton, saveButton].filter { !$0.isHidden }
        stackViewBackgroundView.isHidden = visibleButtons.isEmpty
        
        sliderBackgroundView.backgroundColor = .deepBlue
        sliderBackgroundView.layer.cornerRadius = 25
        sliderBackgroundView.layer.masksToBounds = true
        view.addSubview(sliderBackgroundView)
        
        sliderBackgroundView.snp.makeConstraints { make in
            make.bottom.equalTo(stackViewBackgroundView.snp.top).offset(-50)
            make.centerX.equalTo(stackViewBackgroundView)
            make.width.height.equalTo(50)
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
        if let image = captureScreenshotExcludingViews([buttonStackView, stackViewBackgroundView, sliderBackgroundView]) {
            let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    // 分享到日記的方法
    func shareToDiary() {
        guard let combinedImage = captureScreenshotExcludingViews([buttonStackView, stackViewBackgroundView, sliderBackgroundView]) else {
            print("无法捕捉合成后的图片")
            return
        }
        let postVC = PostViewController()
        
        postVC.sharedImage = combinedImage
        postVC.selectedTrip = self.selectedTrip
        self.navigationController?.pushViewController(postVC, animated: true)
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
}

extension PhotoUploadViewController {
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // 確定比例，取最小值
        let ratio = min(widthRatio, heightRatio)

        // 計算新尺寸
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        // 重繪圖片
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage ?? image // 確保即使失敗也返回原圖
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
    
    func ensureImageViewWithinBounds() {
        let imageFrame = imageView.frame
        let superviewBounds = view.bounds
        
        var newCenter = imageView.center
        
        if imageFrame.minX > 0 {
            newCenter.x = imageView.frame.width / 2
        } else if imageFrame.maxX < superviewBounds.width {
            newCenter.x = superviewBounds.width - imageView.frame.width / 2
        }
        
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
        if let screenshot = captureScreenshotExcludingViews([uploadButton, saveButton,cameraButton, shareButton, stackViewBackgroundView, sliderBackgroundView]) {
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            dismiss(animated: true, completion: {
                let resizedImage = self.resizeImage(image: selectedImage, targetSize: CGSize(width: 1000, height: 1000))
                self.imageView.image = resizedImage
                self.currentCIImage = CIImage(image: resizedImage)
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
}
