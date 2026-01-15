//
//  ProductsPageVM.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 14.01.2026.
//

import Foundation
import RxSwift
import RxCocoa

enum SortOption: Equatable {
    case none
    case priceAsc
    case priceDesc

    var title: String {
        switch self {
        case .none: return "Varsayılan"
        case .priceAsc: return "Fiyat Artan"
        case .priceDesc: return "Fiyat Azalan"
        }
    }
}

protocol ProductsPageVMType {
    var products: BehaviorRelay<[Product]> { get }
    var isLoading: BehaviorRelay<Bool> { get }
    var errorMessage: BehaviorRelay<String?> { get }
    var currentQuery: BehaviorRelay<String> { get }

    var availableCategories: BehaviorRelay<[String]> { get }
    var selectedCategory: BehaviorRelay<String?> { get }
    var selectedSort: BehaviorRelay<SortOption> { get }

    var presentSortSheet: PublishRelay<Void> { get }
    var presentFilterSheet: PublishRelay<Void> { get }

    func loadInitial()
    func updateQuery(_ query: String)

    func sortTapped()
    func filterTapped()

    func setSort(_ option: SortOption)
    func setCategory(_ category: String?)
}

final class ProductsPageVM: ProductsPageVMType {

    let products = BehaviorRelay<[Product]>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)
    let errorMessage = BehaviorRelay<String?>(value: nil)
    let currentQuery = BehaviorRelay<String>(value: "")

    let availableCategories = BehaviorRelay<[String]>(value: [])
    let selectedCategory = BehaviorRelay<String?>(value: nil)
    let selectedSort = BehaviorRelay<SortOption>(value: .none)

    let presentSortSheet = PublishRelay<Void>()
    let presentFilterSheet = PublishRelay<Void>()

    private let service: ProductsServiceType
    private let disposeBag = DisposeBag()
    private let requestDisposable = SerialDisposable()
    private let allProducts = BehaviorRelay<[Product]>(value: [])

    init(service: ProductsServiceType) {
        self.service = service

        Observable.combineLatest(selectedCategory, selectedSort)
            .subscribe(onNext: { [weak self] _, _ in
                self?.applyCategoryAndSort()
            })
            .disposed(by: disposeBag)
    }

    func loadInitial() {
        currentQuery.accept("")
        fetchProducts()
    }

    func updateQuery(_ query: String) {
        currentQuery.accept(query)
        fetchProducts()
    }

    func sortTapped() {
        presentSortSheet.accept(())
    }

    func filterTapped() {
        presentFilterSheet.accept(())
    }

    func setSort(_ option: SortOption) {
        selectedSort.accept(option)
    }

    func setCategory(_ category: String?) {
        selectedCategory.accept(category)
    }

    private func fetchProducts() {
        isLoading.accept(true)
        errorMessage.accept(nil)
        requestDisposable.disposable.dispose()

        let q = currentQuery.value.trimmingCharacters(in: .whitespacesAndNewlines)

        let request: Observable<[Product]> = q.isEmpty
        ? service.fetchAll()
        : service.search(query: q)

        let disposable = request
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] list in
                    guard let self else { return }
                    self.isLoading.accept(false)

                    self.allProducts.accept(list)
                    self.updateCategories(from: list)
                    self.applyCategoryAndSort()
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

    private func updateCategories(from list: [Product]) {
        let cats = Array(Set(list.map { $0.category ?? "" })).sorted()
        availableCategories.accept(cats)

        if let sel = selectedCategory.value, cats.contains(sel) == false {
            selectedCategory.accept(nil)
        }
    }

    private func applyCategoryAndSort() {
        var result = allProducts.value

        if let cat = selectedCategory.value {
            result = result.filter { $0.category == cat }
        }

        switch selectedSort.value {
        case .none:
            break
        case .priceAsc:
            result = result.sorted { $0.price < $1.price }
        case .priceDesc:
            result = result.sorted { $0.price > $1.price }
        }

        products.accept(result)
    }
}


