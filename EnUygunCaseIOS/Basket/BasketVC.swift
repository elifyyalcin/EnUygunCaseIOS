//
//  BasketVC.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 14.01.2026.
//
import Foundation
import RxSwift
import RxCocoa
import UIKit

final class BasketVC: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    @IBOutlet private weak var priceLeftLabel: UILabel!
    @IBOutlet private weak var discountLeftLabel: UILabel!
    @IBOutlet private weak var totalLeftLabel: UILabel!

    @IBOutlet private weak var priceValueLabel: UILabel!
    @IBOutlet private weak var discountValueLabel: UILabel!
    @IBOutlet private weak var totalValueLabel: UILabel!

    @IBOutlet private weak var checkoutButton: UIButton!

    private let viewModel: BasketVMType
    private let disposeBag = DisposeBag()

    init(viewModel: BasketVMType) {
        self.viewModel = viewModel
        super.init(nibName: "BasketVC", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTable()
        bind()
        viewModel.load()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        priceLeftLabel.text = "Price:"
        discountLeftLabel.text = "Discount:"
        totalLeftLabel.text = "Total:"

        checkoutButton.setTitle("CHECKOUT", for: .normal)
        checkoutButton.backgroundColor = UIColor.systemGray4
        checkoutButton.layer.cornerRadius = 16
        checkoutButton.layer.masksToBounds = true
    }

    private func setupTable() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 90
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)

        tableView.register(UINib(nibName: "BasketItemCell", bundle: nil),
                           forCellReuseIdentifier: BasketItemCell.reuseID)
    }

    private func bind() {
        // Summary
        viewModel.priceText.bind(to: priceValueLabel.rx.text).disposed(by: disposeBag)
        viewModel.discountText.bind(to: discountValueLabel.rx.text).disposed(by: disposeBag)
        viewModel.totalText.bind(to: totalValueLabel.rx.text).disposed(by: disposeBag)

        // Table items
        viewModel.lines
            .observe(on: MainScheduler.instance)
            .bind(to: tableView.rx.items(cellIdentifier: BasketItemCell.reuseID, cellType: BasketItemCell.self)) { [weak self] row, line, cell in
                guard let self else { return }
                cell.configure(line: line)

                cell.onTapPlus = { [weak self] in
                    self?.viewModel.increase(productId: line.product.id)
                }
                cell.onTapMinus = { [weak self] in
                    self?.viewModel.decrease(productId: line.product.id)
                }
                cell.onTapTrash = { [weak self] in
                    self?.viewModel.remove(productId: line.product.id)
                }
            }
            .disposed(by: disposeBag)

        checkoutButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showSimpleAlert(message: "Checkout (case) - not implemented")
            })
            .disposed(by: disposeBag)
    }

    private func showSimpleAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
