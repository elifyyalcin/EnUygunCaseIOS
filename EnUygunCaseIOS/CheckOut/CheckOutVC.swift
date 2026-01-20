//
//  CheckOutVC.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 14.01.2026.
//

import UIKit
import RxSwift
import RxCocoa

final class CheckoutVC: UIViewController {

    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var phoneTextField: UITextField!
    @IBOutlet private weak var payButton: UIButton!

    private let viewModel: CheckoutVMType
    private let disposeBag = DisposeBag()

    init(viewModel: CheckoutVMType) {
        self.viewModel = viewModel
        super.init(nibName: "CheckOutVC", bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        nameTextField.placeholder = "NAME"
        emailTextField.placeholder = "EMAIL"
        phoneTextField.placeholder = "PHONE"

        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no

        phoneTextField.keyboardType = .phonePad

        payButton.setTitle("PAY", for: .normal)
        payButton.backgroundColor = .systemGray4
        payButton.layer.cornerRadius = 16
        payButton.layer.masksToBounds = true
    }

    private func bind() {
        nameTextField.rx.text.orEmpty.bind(to: viewModel.name).disposed(by: disposeBag)
        emailTextField.rx.text.orEmpty.bind(to: viewModel.email).disposed(by: disposeBag)
        phoneTextField.rx.text.orEmpty.bind(to: viewModel.phone).disposed(by: disposeBag)

        payButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.view.endEditing(true)
                self?.viewModel.payTapped()
            })
            .disposed(by: disposeBag)

        viewModel.validationMessage
            .observe(on: MainScheduler.instance)
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] msg in
                self?.showErrorAlert(message: msg)
            })
            .disposed(by: disposeBag)

        viewModel.paymentSucceeded
            .observe(on: MainScheduler.instance)
            .filter { $0 }
            .subscribe(onNext: { [weak self] _ in
                self?.showSuccessAlert()
            })
            .disposed(by: disposeBag)
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Hata", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }

    private func showSuccessAlert() {
        let alert = UIAlertController(title: "Başarılı", message: "Ödeme başarılı.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: { [weak self] _ in
            self?.goBackToCart()
        }))
        present(alert, animated: true)
    }

    private func goBackToCart() {
        tabBarController?.selectedIndex = 0

        if let nav = tabBarController?.viewControllers?.first as? UINavigationController {
            nav.popToRootViewController(animated: true)
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
    }
}
