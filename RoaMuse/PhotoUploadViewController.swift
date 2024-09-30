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

    var imageViewConstraints: [Constraint] = [] // 保存 ImageView 的約束
    let minWidthScale: CGFloat = UIScreen.main.bounds.width
    let minHeightScale: CGFloat = UIScreen.main.bounds.height

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
        setupImageViewConstraints()

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
        
        let screenHeight = UIScreen.main.bounds.height
        let imageAspectRatio = image.size.width / image.size.height

        // 設定 imageView 的高度等於螢幕高度
        let newHeight = screenHeight
        let newWidth = newHeight * imageAspectRatio

        updateImageViewConstraints(width: newWidth, height: newHeight)
    }


    // 设置 imageView 的约束
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
            // 計算縮放後的寬高
            let newWidth = imageView.frame.width * gesture.scale
            let newHeight = imageView.frame.height * gesture.scale

            // 確保縮放後的寬度和高度不小於螢幕的寬度和高度
            if newWidth >= minWidth && newHeight >= minHeight {
                view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            } else {
                // 如果嘗試縮小超出限制，則不再繼續縮小
                let scaleWidth = minWidth / imageView.frame.width
                let scaleHeight = minHeight / imageView.frame.height
                let scaleFactor = max(scaleWidth, scaleHeight)

                view.transform = view.transform.scaledBy(x: scaleFactor, y: scaleFactor)
            }
            
            gesture.scale = 1.0
        }

        // 更新約束以確保縮放後圖片不超出透明區域
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
