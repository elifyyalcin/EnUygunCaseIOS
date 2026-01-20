//
//  ProductsPageVC.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 14.01.2026.
//

import UIKit
import RxSwift
import RxCocoa

final class ProductsPageVC: UIViewController, UIScrollViewDelegate {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var totalLabel: UILabel!
    @IBOutlet private weak var searchTextField: UITextField!
    @IBOutlet private weak var filterButton: UIButton!
    @IBOutlet private weak var sortButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var searchContainerView: UIView!

    private let viewModel: ProductsPageVMType
    private let disposeBag = DisposeBag()
    private let favoritesStore: FavoritesStoreType
    private let basketStore: BasketStoreType

    init(viewModel: ProductsPageVMType,
         favoritesStore: FavoritesStoreType,
         basketStore: BasketStoreType) {

        self.viewModel = viewModel
        self.favoritesStore = favoritesStore
        self.basketStore = basketStore
        super.init(nibName: "ProductsPageVC", bundle: nil)
    }

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTable()
        bind()
        viewModel.loadInitial()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        titleLabel.text = "Ürünler"

        searchContainerView.backgroundColor = .white
        searchContainerView.layer.cornerRadius = 18
        searchContainerView.layer.borderWidth = 1
        searchContainerView.layer.borderColor = UIColor.systemGray3.cgColor
        searchContainerView.layer.masksToBounds = true

        searchTextField.borderStyle = .none
        searchTextField.backgroundColor = .clear
        searchTextField.placeholder = "Search Product"
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.autocorrectionType = .no
        searchTextField.autocapitalizationType = .none
        searchTextField.returnKeyType = .search
        searchTextField.font = .systemFont(ofSize: 16, weight: .regular)

        stylePillButton(filterButton, title: "Filter", systemImage: "line.3.horizontal.decrease")
        stylePillButton(sortButton, title: "Sort", systemImage: "arrow.up.arrow.down")
    }

    private func stylePillButton(_ button: UIButton, title: String, systemImage: String) {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: systemImage)
        config.baseForegroundColor = .systemGray

        config.imagePlacement = .leading
        config.imagePadding = 4
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)

        config.attributedTitle = AttributedString(
            title,
            attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 11, weight: .medium)
            ])
        )

        button.configuration = config

        button.backgroundColor = .white
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray3.cgColor
        button.layer.masksToBounds = true
    }

    private func setupTable() {
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 110
        tableView.backgroundColor = .clear

        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)

        tableView.register(ProductListItemCell.self,
                           forCellReuseIdentifier: ProductListItemCell.reuseID)
    }
}

// MARK: - Bindings
private extension ProductsPageVC {
    
    private func bind() {
        searchTextField.rx.text.orEmpty
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .distinctUntilChanged()
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] query in
                self?.viewModel.updateQuery(query)
            })
            .disposed(by: disposeBag)

        filterButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.viewModel.filterTapped()
            })
            .disposed(by: disposeBag)

        viewModel.products
            .observe(on: MainScheduler.instance)
            .bind(to: tableView.rx.items(
                cellIdentifier: ProductListItemCell.reuseID,
                cellType: ProductListItemCell.self
            )) { _, product, cell in
                cell.configure(product: product)
            }
            .disposed(by: disposeBag)

        viewModel.products
            .map { "(Toplam \($0.count) adet)" }
            .distinctUntilChanged()
            .bind(to: totalLabel.rx.text)
            .disposed(by: disposeBag)

        tableView.rx.itemSelected
            .withLatestFrom(viewModel.products) { indexPath, products in
                (indexPath, products[indexPath.row])
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] indexPath, product in
                guard let self else { return }

                self.tableView.deselectRow(at: indexPath, animated: true)

                let detailVM = ProductDetailViewModel(
                    product: product,
                    favoritesStore: self.favoritesStore,
                    basketStore: self.basketStore
                )
                let detailVC = ProductDetailViewController(viewModel: detailVM)


                self.navigationController?.pushViewController(detailVC, animated: true)
            })
            .disposed(by: disposeBag)

        viewModel.presentSortSheet
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.presentSortBottomSheet()
            })
            .disposed(by: disposeBag)

        viewModel.presentFilterSheet
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.presentFilterBottomSheet()
            })
            .disposed(by: disposeBag)
        
        viewModel.errorMessage
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] msg in
                self?.showSimpleAlert(message: msg)
            })
            .disposed(by: disposeBag)
        
        sortButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.viewModel.sortTapped()
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Bottomsheets and alerts
private extension ProductsPageVC {
    
    private func presentSortBottomSheet() {
        let options: [(String, SortOption)] = [
            ("Varsayılan", .none),
            ("Fiyat Artan", .priceAsc),
            ("Fiyat Azalan", .priceDesc)
        ]

        let selectedTitle = options.first(where: { $0.1 == viewModel.selectedSort.value })?.0

        let sheet = OptionSheetVC(
            title: "Sırala",
            options: options.map { $0.0 },
            selected: selectedTitle,
            onSelect: { [weak self] picked in
                guard let self, let picked else { return }
                let opt = options.first(where: { $0.0 == picked })?.1 ?? .none
                self.viewModel.setSort(opt)
            }
        )

        presentAsBottomSheet(sheet)
    }

    private func presentFilterBottomSheet() {
        let cats = viewModel.availableCategories.value
        let options = ["Tümü"] + cats

        let selected = viewModel.selectedCategory.value ?? "Tümü"

        let sheet = OptionSheetVC(
            title: "Filtrele",
            options: options,
            selected: selected,
            onSelect: { [weak self] picked in
                guard let self, let picked else { return }
                if picked == "Tümü" {
                    self.viewModel.setCategory(nil)
                } else {
                    self.viewModel.setCategory(picked)
                }
            }
        )

        presentAsBottomSheet(sheet)
    }

    private func presentAsBottomSheet(_ vc: UIViewController) {
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet

        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
        }

        present(nav, animated: true)
    }


    private func showSimpleAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}


