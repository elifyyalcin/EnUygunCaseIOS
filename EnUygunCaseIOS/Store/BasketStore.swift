//
//  BasketStore.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 16.01.2026.
//

import RxSwift
import RxCocoa
import Foundation

protocol BasketStoreType {
    var basketChanged: Observable<[BasketLine]> { get }
    func currentBasket() -> [BasketLine]

    func add(product: BasketProductSnapshot, qty: Int) -> Observable<[BasketLine]>
    func increase(productId: String) -> Observable<[BasketLine]>
    func decrease(productId: String) -> Observable<[BasketLine]>
    func remove(productId: String) -> Observable<[BasketLine]>
    func clear() -> Observable<[BasketLine]>
}

final class UserDefaultsBasketStore: BasketStoreType {

    private let key = "basket_lines_v1"
    private let defaults: UserDefaults
    private let relay: BehaviorRelay<[BasketLine]>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.relay = BehaviorRelay(value: Self.load(from: defaults, key: key))
    }

    var basketChanged: Observable<[BasketLine]> { relay.asObservable() }
    func currentBasket() -> [BasketLine] { relay.value }

    func add(product: BasketProductSnapshot, qty: Int = 1) -> Observable<[BasketLine]> {
        var lines = relay.value
        if let idx = lines.firstIndex(where: { $0.product.id == product.id }) {
            lines[idx].quantity += max(1, qty)
        } else {
            lines.append(BasketLine(product: product, quantity: max(1, qty)))
        }
        persist(lines)
        relay.accept(lines)
        return Observable.just(lines)
    }

    func increase(productId: String) -> Observable<[BasketLine]> {
        var lines = relay.value
        guard let idx = lines.firstIndex(where: { $0.product.id == productId }) else {
            return Observable.just(lines)
        }
        lines[idx].quantity += 1
        persist(lines)
        relay.accept(lines)
        return Observable.just(lines)
    }

    func decrease(productId: String) -> Observable<[BasketLine]> {
        var lines = relay.value
        guard let idx = lines.firstIndex(where: { $0.product.id == productId }) else {
            return Observable.just(lines)
        }
        lines[idx].quantity -= 1
        if lines[idx].quantity <= 0 {
            lines.remove(at: idx)
        }
        persist(lines)
        relay.accept(lines)
        return Observable.just(lines)
    }

    func remove(productId: String) -> Observable<[BasketLine]> {
        var lines = relay.value
        lines.removeAll { $0.product.id == productId }
        persist(lines)
        relay.accept(lines)
        return Observable.just(lines)
    }

    func clear() -> Observable<[BasketLine]> {
        let empty: [BasketLine] = []
        persist(empty)
        relay.accept(empty)
        return Observable.just(empty)
    }

    private func persist(_ lines: [BasketLine]) {
        if let data = try? JSONEncoder().encode(lines) {
            defaults.set(data, forKey: key)
        }
    }

    private static func load(from defaults: UserDefaults, key: String) -> [BasketLine] {
        guard let data = defaults.data(forKey: key),
              let lines = try? JSONDecoder().decode([BasketLine].self, from: data) else {
            return []
        }
        return lines
    }
}
