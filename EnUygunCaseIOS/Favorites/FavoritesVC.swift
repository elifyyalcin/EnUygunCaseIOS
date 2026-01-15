//
//  FavoritesVC.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 14.01.2026.
//

import UIKit
import RxSwift
import RxCocoa

final class FavoritesVC: UIViewController {

    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var emptyLabel: UILabel!

    private let viewModel: FavoritesVMType
    private let disposeBag = DisposeBag()

    init(viewModel: FavoritesVMType) {
        self.viewModel = viewModel
        super.init(nibName: "FavoritesVC", bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollection()
        bind()
        viewModel.load()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.isHidden = true
    }

    private func setupCollection() {
        collectionView.backgroundColor = .clear

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        collectionView.collectionViewLayout = layout

        collectionView.register(
            UINib(nibName: "FavoriteItemCell", bundle: nil),
            forCellWithReuseIdentifier: FavoriteItemCell.reuseID
        )

        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
    }

    private func bind() {
        viewModel.items
            .observe(on: MainScheduler.instance)
            .bind(to: collectionView.rx.items(
                cellIdentifier: FavoriteItemCell.reuseID,
                cellType: FavoriteItemCell.self
            )) { [weak self] _, product, cell in
                guard let self else { return }

                cell.configure(product: product)

                cell.onTapHeart = { [weak self] in
                    self?.viewModel.removeFavorite(productId: String(product.id))
                }

                cell.onTapPlus = { [weak self] in
                    self?.viewModel.addToBasket(product: product)
                }
            }
            .disposed(by: disposeBag)

        viewModel.emptyText
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] text in
                self?.emptyLabel.text = text
                self?.emptyLabel.isHidden = (text == nil)
            })
            .disposed(by: disposeBag)
    }
}

extension FavoritesVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let interItem: CGFloat = 12
        let available = collectionView.bounds.width - interItem
        let w = floor(available / 2.0)
        return CGSize(width: w, height: 250)
    }
}
