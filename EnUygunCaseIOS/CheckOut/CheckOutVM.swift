//
//  CheckOutVM.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 14.01.2026.
//

import Foundation
import RxSwift
import RxCocoa

protocol CheckoutVMType {
    var name: BehaviorRelay<String> { get }
    var email: BehaviorRelay<String> { get }
    var phone: BehaviorRelay<String> { get }

    var validationMessage: BehaviorRelay<String?> { get }

    var paymentSucceeded: BehaviorRelay<Bool> { get }

    func payTapped()
}

final class CheckoutVM: CheckoutVMType {

    let name = BehaviorRelay<String>(value: "")
    let email = BehaviorRelay<String>(value: "")
    let phone = BehaviorRelay<String>(value: "")

    let validationMessage = BehaviorRelay<String?>(value: nil)
    let paymentSucceeded = BehaviorRelay<Bool>(value: false)

    private let basketStore: BasketStoreType
    private let disposeBag = DisposeBag()

    init(basketStore: BasketStoreType) {
        self.basketStore = basketStore
    }

    func payTapped() {
        paymentSucceeded.accept(false)

        let n = name.value.trimmingCharacters(in: .whitespacesAndNewlines)
        let e = email.value.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = phone.value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !n.isEmpty else { validationMessage.accept("Name boş olamaz."); return }
        guard !e.isEmpty else { validationMessage.accept("Email boş olamaz."); return }
        guard !p.isEmpty else { validationMessage.accept("Phone boş olamaz."); return }

        guard e.contains("@"), e.contains(".") else {
            validationMessage.accept("Email formatı geçersiz.")
            return
        }

        let digits = p.filter(\.isNumber)
        guard digits.count >= 10 else {
            validationMessage.accept("Phone en az 10 haneli olmalı.")
            return
        }

        validationMessage.accept(nil)

        basketStore.clear()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.paymentSucceeded.accept(true)
            }, onError: { [weak self] _ in
                self?.paymentSucceeded.accept(true)
            })
            .disposed(by: disposeBag)
    }
}
