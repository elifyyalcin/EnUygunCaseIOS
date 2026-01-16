//
//  Untitled.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 16.01.2026.
//
import RxSwift
import RxCocoa
import Foundation

protocol FavoritesStoreType {
    func isFavorite(productId: String) -> Observable<Bool>
    func toggleFavorite(productId: String) -> Observable<Bool>
    func setFavorite(_ isFav: Bool, productId: String) -> Observable<Bool>

    var favoritesChanged: Observable<Set<String>> { get }
    func currentFavorites() -> Set<String>
}

final class UserDefaultsFavoritesStore: FavoritesStoreType {

    private let key = "favorite_product_ids_v1"
    private let defaults: UserDefaults

    private let favoritesRelay: BehaviorRelay<Set<String>>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let initial = Self.loadSet(from: defaults, key: key)
        self.favoritesRelay = BehaviorRelay(value: initial)
    }

    var favoritesChanged: Observable<Set<String>> {
        favoritesRelay.asObservable()
    }

    func currentFavorites() -> Set<String> {
        favoritesRelay.value
    }

    func isFavorite(productId: String) -> Observable<Bool> {
        Observable.just(favoritesRelay.value.contains(productId))
    }

    func toggleFavorite(productId: String) -> Observable<Bool> {
        var set = favoritesRelay.value
        let newState: Bool
        if set.contains(productId) {
            set.remove(productId)
            newState = false
        } else {
            set.insert(productId)
            newState = true
        }
        persist(set)
        favoritesRelay.accept(set)
        return Observable.just(newState)
    }

    func setFavorite(_ isFav: Bool, productId: String) -> Observable<Bool> {
        var set = favoritesRelay.value
        if isFav {
            set.insert(productId)
        } else {
            set.remove(productId)
        }
        persist(set)
        favoritesRelay.accept(set)
        return Observable.just(isFav)
    }

    private func persist(_ set: Set<String>) {
        defaults.set(Array(set), forKey: key)
    }

    private static func loadSet(from defaults: UserDefaults, key: String) -> Set<String> {
        let arr = defaults.array(forKey: key) as? [String] ?? []
        return Set(arr)
    }
}
