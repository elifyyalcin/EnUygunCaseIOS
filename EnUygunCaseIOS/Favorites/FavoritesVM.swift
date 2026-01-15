//
//  FavoritesVM.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 14.01.2026.
//

import Foundation
import RxSwift
import RxCocoa

protocol FavoritesVMType {
    var items: BehaviorRelay<[Product]> { get }      // collection datası
    var emptyText: BehaviorRelay<String?> { get }    // "Favori yok" mesajı

    func load()
    func removeFavorite(productId: String)
    func addToBasket(product: Product)
}

final class FavoritesVM: FavoritesVMType {

    let items = BehaviorRelay<[Product]>(value: [])
    let emptyText = BehaviorRelay<String?>(value: nil)

    private let favoritesStore: FavoritesStoreType
    private let basketStore: BasketStoreType
    private let productsService: ProductsServiceType

    private let disposeBag = DisposeBag()

    private var allProductsCache: [Product] = []

    init(favoritesStore: FavoritesStoreType,
         basketStore: BasketStoreType,
         productsService: ProductsServiceType) {

        self.favoritesStore = favoritesStore
        self.basketStore = basketStore
        self.productsService = productsService

        // Favoriler değişince UI datasını yenile
        favoritesStore.favoritesChanged
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] favIds in
                self?.applyFavorites(favIds: favIds)
            })
            .disposed(by: disposeBag)
    }

    func load() {
        applyFavorites(favIds: favoritesStore.currentFavorites())

        productsService.fetchAll()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] products in
                    self?.allProductsCache = products
                    self?.applyFavorites(favIds: self?.favoritesStore.currentFavorites() ?? [])
                },
                onError: { [weak self] _ in
                    // servis hata verirse, en azından boş mesajı göster
                    self?.applyFavorites(favIds: self?.favoritesStore.currentFavorites() ?? [])
                }
            )
            .disposed(by: disposeBag)
    }

    func removeFavorite(productId: String) {
        favoritesStore.setFavorite(false, productId: productId)
            .subscribe()
            .disposed(by: disposeBag)
    }

    func addToBasket(product: Product) {
        var oldPrice: Double? = 0
        let discount = product.discountPercentage ?? 0
        if discount > 0 {
            let current = Double(product.price)
            let old = current / (1.0 - (discount / 100.0))
            oldPrice = old
        }
        
        let snap = BasketProductSnapshot(
            id: String(product.id),
            title: product.title,
            price: product.price,
            oldPrice: oldPrice,
            imageURL: product.images?.first
        )

        basketStore.add(product: snap, qty: 1)
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func applyFavorites(favIds: Set<String>) {
        // cache boşsa kart gösteremezsin (sadece empty state)
        guard !allProductsCache.isEmpty else {
            let isEmpty = favIds.isEmpty
            items.accept([])
            emptyText.accept(isEmpty ? "Favori ürününüz yok." : "Favoriler yükleniyor...")
            return
        }

        let favList = allProductsCache.filter { favIds.contains(String($0.id)) }
        items.accept(favList)
        emptyText.accept(favList.isEmpty ? "Favori ürününüz yok." : nil)
    }
}
