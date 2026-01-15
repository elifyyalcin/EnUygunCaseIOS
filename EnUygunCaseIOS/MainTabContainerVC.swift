//
//  MainTabContainerVC.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 14.01.2026.
//

import UIKit
import RxSwift
import RxCocoa

protocol MainTabChildFactoryType {
    func makeHome() -> UIViewController
    func makeFavorites() -> UIViewController
    func makeBasket() -> UIViewController
}

final class MainTabChildFactory: MainTabChildFactoryType {
    func makeHome() -> UIViewController {
        let service = ProductsService()
        let vm = ProductsPageVM(service: service)
        return ProductsPageVC(viewModel: vm)
    }

    func makeFavorites() -> UIViewController {
        return PlaceholderVC(titleText: "Favorites")
    }

    func makeBasket() -> UIViewController {
        return PlaceholderVC(titleText: "Basket")
    }
}

final class MainTabContainerVC: UIViewController {

    @IBOutlet private weak var tabBarContainerView: UIView!
    @IBOutlet private weak var contentContainerView: UIView!

    @IBOutlet private weak var homeButton: UIButton!
    @IBOutlet private weak var favoritesButton: UIButton!
    @IBOutlet private weak var basketButton: UIButton!

    private let factory: MainTabChildFactoryType
    private let disposeBag = DisposeBag()
    private var currentChild: UIViewController?

    init(factory: MainTabChildFactoryType) {
        self.factory = factory
        super.init(nibName: "MainTabContainerVC", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(factory:) instead.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindTabs()
        switchTo(.home)
        applyTabUI(.home)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tabBarContainerView.backgroundColor = .systemGray5
        tabBarContainerView.layer.cornerRadius = 20
        tabBarContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        tabBarContainerView.layer.masksToBounds = true
    }

    private func bindTabs() {
        homeButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.switchTo(.home)
                self?.applyTabUI(.home)
            })
            .disposed(by: disposeBag)

        favoritesButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.switchTo(.favorites)
                self?.applyTabUI(.favorites)
            })
            .disposed(by: disposeBag)

        basketButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.switchTo(.basket)
                self?.applyTabUI(.basket)
            })
            .disposed(by: disposeBag)
    }

    private func switchTo(_ tab: Tab) {
        // eski child’ı kaldır
        if let currentChild {
            currentChild.willMove(toParent: nil)
            currentChild.view.removeFromSuperview()
            currentChild.removeFromParent()
        }

        // yeni child oluştur
        let newVC: UIViewController
        switch tab {
        case .home: newVC = factory.makeHome()
        case .favorites: newVC = factory.makeFavorites()
        case .basket: newVC = factory.makeBasket()
        }

        // child ekle
        addChild(newVC)
        newVC.view.frame = contentContainerView.bounds
        newVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentContainerView.addSubview(newVC.view)
        newVC.didMove(toParent: self)

        currentChild = newVC
    }

    private func applyTabUI(_ tab: Tab) {
        homeButton.alpha = 0.4
        favoritesButton.alpha = 0.4
        basketButton.alpha = 0.4

        switch tab {
        case .home: homeButton.alpha = 1
        case .favorites: favoritesButton.alpha = 1
        case .basket: basketButton.alpha = 1
        }
    }

    enum Tab { case home, favorites, basket }
}
