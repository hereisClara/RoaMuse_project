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
        navigationItem.backButtonTitle = ""
        self.title = "首頁"
        startAutoScrolling()
        setupCollectionView()
        getPoems()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    func setupUI() {
        
        let iconImageView = UIImageView(image: UIImage(named: "maskImageAtLogin"))
        view.addSubview(iconImageView)
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            make.bottom.equalTo(collectionView.snp.top).offset(-40)
            make.leading.equalTo(view).offset(10)
            make.width.equalTo(view.snp.width).multipliedBy(0.5)
        }
        
        let chatButton = UIButton(type: .system)
        view.addSubview(chatButton)
        chatButton.setImage(UIImage(systemName: "bubble.left.and.bubble.right.fill"), for: .normal)
        chatButton.tintColor = .accent
        chatButton.snp.makeConstraints { make in
            make.trailing.equalTo(collectionView.snp.trailing)
            make.centerY.equalTo(iconImageView)
            make.width.height.equalTo(40)
        }
        
        chatButton.addTarget(self, action: #selector(toChatPage), for: .touchUpInside)
    }
    
    @objc func toChatPage() {
        
        if self.navigationController == nil {
            print("This view controller is not inside a navigation controller.")
        }
        
        let chatListVC = ChatListViewController()
        self.navigationController?.pushViewController(chatListVC, animated: true)
        
    }
    
    func addGradientBlurEffectToView() {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        view.addSubview(blurEffectView)
        setupUI()
        blurEffectView.snp.makeConstraints { make in
            make.top.equalTo(view)
            make.leading.trailing.equalTo(view)
            make.height.equalTo(view).multipliedBy(0.15)
        }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.7).cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.05)
        
        blurEffectView.layer.mask = gradientLayer
        
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
        
        navigationBar.setBackgroundImage(nil, for: .default)
        navigationBar.shadowImage = nil
        navigationBar.isTranslucent = false
        navigationBar.backgroundColor = nil
    }
    
    func setupCollectionView() {
        let layout = CHTCollectionViewWaterfallLayout()
        layout.minimumColumnSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.columnCount = 4
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PoemCell.self, forCellWithReuseIdentifier: "PoemCell")
        collectionView.backgroundColor = .backgroundGray
        collectionView.layer.cornerRadius = 20
        collectionView.layer.masksToBounds = true

        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.allowsSelection = true

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(15)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(view.frame.height * 0.1)
        }
    }
    
    func startAutoScrolling() {
        autoScrollTimer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(handleAutoScroll), userInfo: nil, repeats: true)
    }
    
    func stopAutoScrolling() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    @objc func handleAutoScroll() {
        let currentOffset = collectionView.contentOffset.y
        let newOffset = CGPoint(x: 0, y: currentOffset + 0.5) 
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return poems.isEmpty ? 0 : numberOfItems
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PoemCell", for: indexPath) as? PoemCell else {
            return UICollectionViewCell()
        }
        
        let poem = poems[indexPath.item % poems.count]
        cell.configure(with: poem.title)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == numberOfItems - 5 && poems.count > 0 {
                
                let newItems = numberOfItems + 15
                let indexPaths = (numberOfItems..<newItems).map { IndexPath(item: $0, section: 0) }
                numberOfItems = newItems
                
                collectionView.performBatchUpdates({
                    collectionView.insertItems(at: indexPaths)
                }, completion: nil)
            }
        }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let poem = poems[indexPath.item % poems.count]
        let height = calculateHeight(for: poem.title)
        return CGSize(width: (collectionView.bounds.width / 2) - 30, height: height)
    }
    
    func calculateHeight(for text: String) -> CGFloat {
        let baseHeight: CGFloat = 50
        let additionalHeight = CGFloat(text.count) * 70
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
        contentView.backgroundColor = .deepBlue
        contentView.layer.cornerRadius = 20
        
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 24)
        titleLabel.textColor = .forBronze
        titleLabel.lineBreakMode = .byCharWrapping
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }
    }
    
    func configure(with title: String) {
        
        let verticalTitle = title.map { String($0) }.joined(separator: "\n")
        titleLabel.text = verticalTitle
    }
}
