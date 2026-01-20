//
//  BasketVM.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 14.01.2026.
//

import Foundation
import RxSwift
import RxCocoa

protocol BasketVMType {
    var lines: BehaviorRelay<[BasketLine]> { get }

    var priceText: BehaviorRelay<String> { get }
    var discountText: BehaviorRelay<String> { get }
    var totalText: BehaviorRelay<String> { get }

    func load()
    func increase(productId: String)
    func decrease(productId: String)
    func remove(productId: String)
}

final class BasketVM: BasketVMType {

    let lines = BehaviorRelay<[BasketLine]>(value: [])

    let priceText = BehaviorRelay<String>(value: "0 TL")
    let discountText = BehaviorRelay<String>(value: "0 TL")
    let totalText = BehaviorRelay<String>(value: "0 TL")

    private let store: BasketStoreType
    private let disposeBag = DisposeBag()

    init(store: BasketStoreType) {
        self.store = store

        store.basketChanged
            .subscribe(onNext: { [weak self] lines in
                self?.lines.accept(lines)
                self?.recalculate(lines)
            })
            .disposed(by: disposeBag)
    }

    func load() {
        let current = store.currentBasket()
        lines.accept(current)
        recalculate(current)
    }

    func increase(productId: String) { store.increase(productId: productId).subscribe().disposed(by: disposeBag) }
    func decrease(productId: String) { store.decrease(productId: productId).subscribe().disposed(by: disposeBag) }
    func remove(productId: String)   { store.remove(productId: productId).subscribe().disposed(by: disposeBag) }

    private func recalculate(_ lines: [BasketLine]) {
        let price = lines.reduce(0.0) { acc, line in
            let base = line.product.oldPrice ?? line.product.price
            return acc + Double(line.quantity) * base
        }

        let discount = lines.reduce(0.0) { acc, line in
            return acc + Double(line.quantity) * line.product.discountAmountPerItem
        }
        let total = max(0, price - discount)

        priceText.accept(Money.tl(price))
        discountText.accept(Money.tl(discount))
        totalText.accept(Money.tl(total))
    }
}

enum Money {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "tr_TR")

        f.currencyCode = "TRY"
        f.currencySymbol = "₺"

        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }()

    static func tl(_ value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "₺0,00"
    }
}
