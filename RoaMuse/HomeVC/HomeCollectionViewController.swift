import UIKit
import SnapKit
import CHTCollectionViewWaterfallLayout

class HomeCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, CHTCollectionViewDelegateWaterfallLayout {
    
    var poems = [Poem]()
    var collectionView: UICollectionView!
    var autoScrollTimer: Timer?
    var numberOfItems = 30
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundGray
        self.title = "首頁"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        if let customFont = UIFont(name: "NotoSerifHK-Black", size: 40) {
            navigationController?.navigationBar.largeTitleTextAttributes = [
                .foregroundColor: UIColor.white,  // 修改大標題顏色
                .font: customFont  // 自定義字體
            ]
        }
        
        startAutoScrolling()
        setupCollectionView()
        getPoems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        // 設置 Navigation Bar 透明
        //        makeNavigationBarTransparent()
        addGradientBlurEffectToView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //        restoreNavigationBarStyle()
    }
    
    func setupUI() {
        
        let iconImageView = UIImageView(image: UIImage(named: "homeVC title2"))
        view.addSubview(iconImageView)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.snp.makeConstraints { make in
            make.top.equalTo(view).offset(20)
            make.width.equalTo(160)
            make.height.equalTo(400)
        }
    }
    
    func addGradientBlurEffectToView() {
        // 1. 創建 UIVisualEffectView 以實現模糊效果
        let blurEffect = UIBlurEffect(style: .dark) // 可以根據需要改變為 .dark 或 .extraLight
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        view.addSubview(blurEffectView)
        setupUI()
        blurEffectView.snp.makeConstraints { make in
            make.top.equalTo(view)
            make.leading.trailing.equalTo(view)
            make.height.equalTo(view).multipliedBy(0.2)
        }
        
        // 4. 創建一個漸變遮罩來控制模糊效果的範圍
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.9).cgColor] // 從透明到模糊漸變
        gradientLayer.locations = [0.0, 1.0] // 從透明到白色的漸變位置
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0) // 從頂部開始漸變
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0) // 到底部結束漸變
        
        // 5. 將 gradientLayer 添加到 blurEffectView 並設置遮罩
        blurEffectView.layer.mask = gradientLayer
        
        // 6. 更新漸變圖層的 frame，當使用 SnapKit 佈局時需要在佈局完成後設置
        blurEffectView.layoutIfNeeded()
        gradientLayer.frame = blurEffectView.bounds
    }
    
    func makeNavigationBarTransparent() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.backgroundColor = .clear
        navigationBar.isTranslucent = true
    }
    
    func restoreNavigationBarStyle() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        
        // 恢復到默認的樣式
        navigationBar.setBackgroundImage(nil, for: .default)
        navigationBar.shadowImage = nil
        navigationBar.isTranslucent = false
        navigationBar.backgroundColor = nil
    }
    
    func setupCollectionView() {
        let layout = CHTCollectionViewWaterfallLayout()
        layout.minimumColumnSpacing = 12 // 列之間的間距
        layout.minimumInteritemSpacing = 12 // 行之間的間距
        layout.columnCount = 4 // 設置列數，可以根據需要調整
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PoemCell.self, forCellWithReuseIdentifier: "PoemCell")
        collectionView.backgroundColor = .backgroundGray
        collectionView.layer.cornerRadius = 20
        collectionView.layer.masksToBounds = true
        collectionView.alwaysBounceVertical = true // 總是允許垂直滾動
        collectionView.showsVerticalScrollIndicator = false // 隱藏垂直滾動條
        collectionView.showsHorizontalScrollIndicator = false // 隱藏水平滾動條
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-15)
            make.top.equalTo(view).offset(-30)
        }
    }
    
    func startAutoScrolling() {
        autoScrollTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(handleAutoScroll), userInfo: nil, repeats: true)
    }
    
    func stopAutoScrolling() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    @objc func handleAutoScroll() {
        let currentOffset = collectionView.contentOffset.y
        let newOffset = CGPoint(x: 0, y: currentOffset + 1) // 每次向下滾動 1 點
        let maxOffset = collectionView.contentSize.height - collectionView.bounds.height
        
        if newOffset.y >= maxOffset {
            collectionView.setContentOffset(CGPoint.zero, animated: false)
        } else {
            collectionView.setContentOffset(newOffset, animated: false)
        }
    }
    
    func getPoems() {
        FirebaseManager.shared.loadAllPoems { poems in
            self.poems = poems
            self.collectionView.reloadData()
        }
    }
    
    // MARK: - UICollectionView DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return poems.isEmpty ? 0 : numberOfItems // 返回較大的數字模擬無限滾動
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PoemCell", for: indexPath) as? PoemCell else {
            return UICollectionViewCell()
        }
        
        let poem = poems[indexPath.item % poems.count] // 重用詩
        cell.configure(with: poem.title)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == numberOfItems - 5 && poems.count > 0 {
                // 更新數據源，動態增加 15 個項目
                let newItems = numberOfItems + 15
                let indexPaths = (numberOfItems..<newItems).map { IndexPath(item: $0, section: 0) }
                numberOfItems = newItems
                
                // 使用 performBatchUpdates 插入新項目，避免畫面閃動
                collectionView.performBatchUpdates({
                    collectionView.insertItems(at: indexPaths)
                }, completion: nil)
            }
        }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 防止 poems 数组为空导致崩溃
        guard !poems.isEmpty else {
            return
        }
        
        var selectedIndex = indexPath.row % poems.count
        
        if selectedIndex == 0 && indexPath.row != 0 {
            selectedIndex = poems.count - 1
        }
        
        let selectedPoem = poems[selectedIndex]
        let poemPostVC = PoemPostViewController()
        
        poemPostVC.selectedPoem = selectedPoem
        print("Selected poem title: \(selectedPoem.title)")
        navigationController?.pushViewController(poemPostVC, animated: true)
    }
    
    // MARK: - CHTCollectionViewDelegateWaterfallLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let poem = poems[indexPath.item % poems.count]
        let height = calculateHeight(for: poem.title)
        return CGSize(width: (collectionView.bounds.width / 2) - 30, height: height) // 每個 item 的寬度為 2 列，並根據內容動態調整高度
    }
    
    func calculateHeight(for text: String) -> CGFloat {
        let baseHeight: CGFloat = 50 // 基礎高度，保證最短的 cell 也有一定高度
        let additionalHeight = CGFloat(text.count) * 70 // 根據每個字增加高度，調整以適合視覺效果
        return baseHeight + additionalHeight
    }
}

class PoemCell: UICollectionViewCell {
    
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        contentView.backgroundColor = .deepBlue // 深藍色背景
        contentView.layer.cornerRadius = 20
        
        titleLabel.numberOfLines = 0 // 允許多行顯示
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 24)
        titleLabel.textColor = .forBronze // 白色文字
        titleLabel.lineBreakMode = .byCharWrapping // 按字符換行，模仿中文直式排列
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10) // 設置內部 padding
        }
    }
    
    func configure(with title: String) {
        
        let verticalTitle = title.map { String($0) }.joined(separator: "\n")
        titleLabel.text = verticalTitle
    }
}
