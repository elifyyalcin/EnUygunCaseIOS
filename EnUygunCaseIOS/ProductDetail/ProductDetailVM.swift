//
//  ProductDetailVM.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 14.01.2026.
//

import UIKit
import RxSwift
import RxCocoa

final class ProductDetailViewModel {

    let productTitle = BehaviorRelay<String>(value: "")
    let productSubtitle = BehaviorRelay<String?>(value: nil)
    let priceText = BehaviorRelay<String>(value: "")
    let oldPriceText = BehaviorRelay<String?>(value: nil)

    let imageURLs = BehaviorRelay<[URL]>(value: [])
    let selectedImageIndex = BehaviorRelay<Int>(value: 0)
    let isFavorite = BehaviorRelay<Bool>(value: false)

    private let product: Product
    private let favoritesStore: FavoritesStoreType
    private let disposeBag = DisposeBag()

    init(product: Product, favoritesStore: FavoritesStoreType) {
        self.product = product
        self.favoritesStore = favoritesStore

        productTitle.accept(product.title)
        productSubtitle.accept(product.description)
        priceText.accept(String(product.price))
        
        let discount = product.discountPercentage ?? 0
        if discount > 0 {
            let current = Double(product.price)
            let old = current / (1.0 - (discount / 100.0))
            oldPriceText.accept(String(old))
        }

        let urls = product.images?.compactMap { URL(string: $0) } ?? []
        imageURLs.accept(urls)

        favoritesStore.isFavorite(productId: String(product.id))
            .subscribe(onNext: { [weak self] fav in
                self?.isFavorite.accept(fav)
            }, onError: { [weak self] _ in
                self?.isFavorite.accept(false)
            })
            .disposed(by: disposeBag)
    }

    func favTapped() {
        favoritesStore.toggleFavorite(productId: String(product.id))
            .subscribe(onNext: { [weak self] newState in
                self?.isFavorite.accept(newState)
            }, onError: { _ in
                // keep current state on error
            })
            .disposed(by: disposeBag)
    }

    func didChangeImageIndex(_ index: Int) {
        selectedImageIndex.accept(max(0, index))
    }
}

extension ProductDetailViewModel {
    func basketSnapshot() -> BasketProductSnapshot {
        var oldPrice: Double? = 0
        let discount = product.discountPercentage ?? 0
        if discount > 0 {
            let current = Double(product.price)
            let old = current / (1.0 - (discount / 100.0))
            oldPrice = old
        }
        
        return BasketProductSnapshot(
            id: String(product.id),
            title: product.title,
            price: product.price,
            oldPrice: oldPrice,
            imageURL: product.images?.first
        )
    }
}
