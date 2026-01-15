//
//  ProductsPageVM.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 14.01.2026.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: - ViewModel Protocol

protocol ProductsPageVMType {
    var products: BehaviorRelay<[Product]> { get }
    var isLoading: BehaviorRelay<Bool> { get }
    var errorMessage: BehaviorRelay<String?> { get }
    var currentQuery: BehaviorRelay<String> { get }
    
    func loadInitial()
    func updateQuery(_ query: String)
    func filterTapped()
}

// MARK: - ViewModel Implementation

final class ProductsPageVM: ProductsPageVMType {

    let products = BehaviorRelay<[Product]>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)
    let errorMessage = BehaviorRelay<String?>(value: nil)
    let currentQuery = BehaviorRelay<String>(value: "")
    private let service: ProductsServiceType
    private let disposeBag = DisposeBag()

    // Yeni istek gelince eskisini iptal etmek için
    private let requestDisposable = SerialDisposable()

    init(service: ProductsServiceType) {
        self.service = service
    }

    // İlk açılış
    func loadInitial() {
        currentQuery.accept("")
        fetchProducts() // tüm ürünleri yükle
    }

    // Search input değişince
    func updateQuery(_ query: String) {
        currentQuery.accept(query)
        fetchProducts()
    }

    // Filter butonu (şimdilik yok)
    func filterTapped() {
        errorMessage.accept("Filter ekranı daha sonra eklenecek.")
    }

    // MARK: - Fetch

    private func fetchProducts() {

        // UI state reset
        isLoading.accept(true)
        errorMessage.accept(nil)
        requestDisposable.disposable.dispose() // Eski request varsa iptal et

        let q = currentQuery.value.trimmingCharacters(in: .whitespacesAndNewlines)

        let request: Observable<[Product]>
        if q.isEmpty {
            request = service.fetchAll() // Search yok tüm ürünler
        } else {
            request = service.search(query: q) // Search var search endpoint
        }

        let disposable = request
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] list in
                    guard let self else { return }
                    self.isLoading.accept(false)
                    self.products.accept(list)
                },
                onError: { [weak self] error in
                    guard let self else { return }
                    self.isLoading.accept(false)

                    let ns = error as NSError
                    self.errorMessage.accept("Veri alınamadı: \(ns.localizedDescription)")
                }
            )

        requestDisposable.disposable = disposable
        disposable.disposed(by: disposeBag)
    }
}

