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
    let discountPercentText = BehaviorRelay<String?>(value: nil)
    let toastMessage = PublishRelay<String>()

    let imageURLs = BehaviorRelay<[URL]>(value: [])
    let selectedImageIndex = BehaviorRelay<Int>(value: 0)
    let isFavorite = BehaviorRelay<Bool>(value: false)

    private let product: Product
    private let favoritesStore: FavoritesStoreType
    private let basketStore: BasketStoreType
    
    private let disposeBag = DisposeBag()

    init(product: Product, favoritesStore: FavoritesStoreType, basketStore: BasketStoreType) {
        self.product = product
        self.favoritesStore = favoritesStore
        self.basketStore = basketStore

        productTitle.accept(product.title)
        productSubtitle.accept(product.description)
        priceText.accept(formatMoney(product.price))

        let discount = product.discountPercentage ?? 0
        if discount > 0 {
            let current = product.price
            let old = current / (1.0 - (discount / 100.0))
            oldPriceText.accept(formatMoney(old))
        } else {
            oldPriceText.accept(nil)
        }

        let discountPercentage = Int((product.discountPercentage ?? 0).rounded())
        if discountPercentage > 0 {
            discountPercentText.accept("%\(discountPercentage)")
        } else {
            discountPercentText.accept(nil)
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
    
    func addToCartTapped(qty: Int = 1) {
        let snapshot = basketSnapshot()

        basketStore.add(product: snapshot, qty: qty)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] _ in
                    self?.toastMessage.accept("Added to cart")
                },
                onError: { [weak self] err in
                    let ns = err as NSError
                    self?.toastMessage.accept("Add to cart failed: \(ns.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)
    }

    func didChangeImageIndex(_ index: Int) {
        selectedImageIndex.accept(max(0, index))
    }
}

extension ProductDetailViewModel {
    
    func basketSnapshot() -> BasketProductSnapshot {
        var oldPrice: Double? = nil
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

// MARK: - Formatter

extension ProductDetailViewModel {
    
    private static let moneyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "₺"
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        f.locale = Locale(identifier: "tr_TR")
        return f
    }()

    private func formatMoney(_ value: Double) -> String {
        Self.moneyFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
