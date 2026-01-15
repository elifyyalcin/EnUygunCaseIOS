//
//  ProductDetailVC.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 14.01.2026.
//

import UIKit
import RxSwift
import RxCocoa

final class ProductDetailViewController: UIViewController {

    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var pageControl: UIPageControl!
    @IBOutlet private weak var discountBadgeLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var oldPriceLabel: UILabel!
    @IBOutlet private weak var chartButton: UIButton!

    private let viewModel: ProductDetailViewModel
    private let disposeBag = DisposeBag()

    private var imageURLs: [URL] = []

    private let favButton = UIButton(type: .system)

    init(viewModel: ProductDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "ProductDetailVC", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(viewModel:)")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        bindViewModel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()

        discountBadgeLabel.layer.cornerRadius = discountBadgeLabel.bounds.height / 2
        discountBadgeLabel.layer.masksToBounds = true
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        favButton.setImage(UIImage(systemName: "heart"), for: .normal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: favButton)

        pageControl.hidesForSinglePage = true
        pageControl.isUserInteractionEnabled = false
        pageControl.numberOfPages = 0
        pageControl.currentPage = 0

        titleLabel.numberOfLines = 2
        descriptionLabel.numberOfLines = 0

        oldPriceLabel.isHidden = true
        oldPriceLabel.attributedText = nil

        discountBadgeLabel.textAlignment = .center
        discountBadgeLabel.layer.masksToBounds = true
        discountBadgeLabel.isHidden = true
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView.setCollectionViewLayout(layout, animated: false)

        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false

        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseId)
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    // MARK: - Binding
    private func bindViewModel() {

        viewModel.productTitle
            .subscribe(onNext: { [weak self] t in
                self?.navigationItem.title = t
                self?.titleLabel.text = t
            })
            .disposed(by: disposeBag)

        viewModel.productSubtitle
            .subscribe(onNext: { [weak self] desc in
                self?.descriptionLabel.text = desc ?? ""
            })
            .disposed(by: disposeBag)

        viewModel.priceText
            .subscribe(onNext: { [weak self] p in
                self?.priceLabel.text = p
            })
            .disposed(by: disposeBag)

        viewModel.oldPriceText
            .subscribe(onNext: { [weak self] old in
                guard let self else { return }

                if let old, !old.isEmpty {
                    self.oldPriceLabel.isHidden = false
                    self.oldPriceLabel.attributedText = NSAttributedString(
                        string: old,
                        attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
                    )
                } else {
                    self.oldPriceLabel.isHidden = true
                    self.oldPriceLabel.attributedText = nil
                }

                self.discountBadgeLabel.isHidden = true
            })
            .disposed(by: disposeBag)

        viewModel.imageURLs
            .subscribe(onNext: { [weak self] urls in
                guard let self else { return }
                self.imageURLs = urls
                self.collectionView.reloadData()

                self.pageControl.numberOfPages = urls.count
                self.pageControl.currentPage = 0
                self.viewModel.didChangeImageIndex(0)
            })
            .disposed(by: disposeBag)

        viewModel.selectedImageIndex
            .subscribe(onNext: { [weak self] idx in
                self?.pageControl.currentPage = idx
            })
            .disposed(by: disposeBag)

        viewModel.isFavorite
            .subscribe(onNext: { [weak self] isFav in
                let icon = isFav ? "heart.fill" : "heart"
                self?.favButton.setImage(UIImage(systemName: icon), for: .normal)
            })
            .disposed(by: disposeBag)

        // MARK: - Inputs

        favButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.viewModel.favTapped()
            })
            .disposed(by: disposeBag)

        collectionView.rx.didEndDecelerating
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                let w = max(self.collectionView.bounds.width, 1)
                let page = Int(round(self.collectionView.contentOffset.x / w))
                self.viewModel.didChangeImageIndex(page)
            })
            .disposed(by: disposeBag)
    }

    func setDiscountPercent(_ percent: Int?) {
        guard let percent, percent > 0 else {
            discountBadgeLabel.isHidden = true
            return
        }
        discountBadgeLabel.isHidden = false
        discountBadgeLabel.text = "%\(percent)"
    }
}

// MARK: - CollectionView
extension ProductDetailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imageURLs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.reuseId, for: indexPath) as! ImageCell
        cell.configure(url: imageURLs[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }
}

// MARK: - ImageCell
final class ImageCell: UICollectionViewCell {
    static let reuseId = "ImageCell"

    private var imageTask: URLSessionDataTask?

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        imageView.image = nil
    }

    func configure(url: URL) {
        imageTask?.cancel()
        imageView.image = nil

        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.imageView.image = img
            }
        }
        imageTask?.resume()
    }
}
