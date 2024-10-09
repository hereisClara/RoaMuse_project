import UIKit
import SnapKit
import CHTCollectionViewWaterfallLayout

class HomeCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, CHTCollectionViewDelegateWaterfallLayout {
    
    var poems = [Poem]()
    var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        getPoems() // 獲取詩的數據
    }
    
    func setupCollectionView() {
        let layout = CHTCollectionViewWaterfallLayout()
        layout.minimumColumnSpacing = 12 // 列之間的間距
        layout.minimumInteritemSpacing = 12 // 行之間的間距
        layout.columnCount = 3 // 設置列數，可以根據需要調整
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PoemCell.self, forCellWithReuseIdentifier: "PoemCell")
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true // 總是允許垂直滾動
        collectionView.showsVerticalScrollIndicator = false // 隱藏垂直滾動條
        collectionView.showsHorizontalScrollIndicator = false // 隱藏水平滾動條
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10) // 為 collectionView 設置一些邊距
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
        return poems.isEmpty ? 0 : 10000 // 返回較大的數字模擬無限滾動
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PoemCell", for: indexPath) as? PoemCell else {
            return UICollectionViewCell()
        }
        
        let poem = poems[indexPath.item % poems.count] // 重用詩
        cell.configure(with: poem.title)
        
        return cell
    }
    
    // MARK: - CHTCollectionViewDelegateWaterfallLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let poem = poems[indexPath.item % poems.count]
        let height = calculateHeight(for: poem.title)
        return CGSize(width: (collectionView.bounds.width / 2) - 30, height: height) // 每個 item 的寬度為 2 列，並根據內容動態調整高度
    }
    
    func calculateHeight(for text: String) -> CGFloat {
        let baseHeight: CGFloat = 50 // 基礎高度，保證最短的 cell 也有一定高度
        let additionalHeight = CGFloat(text.count) * 30 // 根據每個字增加高度，調整以適合視覺效果
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
        backgroundColor = .systemBlue // 深藍色背景
        
        titleLabel.numberOfLines = 0 // 允許多行顯示
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 20)
        titleLabel.textColor = .white // 白色文字
        titleLabel.lineBreakMode = .byCharWrapping // 按字符換行，模仿中文直式排列
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10) // 設置內部 padding
        }
    }
    
    func configure(with title: String) {
        // 將每個字符單獨一行顯示
        let verticalTitle = title.map { String($0) }.joined(separator: "\n")
        titleLabel.text = verticalTitle
    }
}
