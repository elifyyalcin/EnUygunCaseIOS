//
//  ProductListItemView.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 14.01.2026.
//

import UIKit

final class ProductListItemView: UIView {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var productImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var discountBadgeLabel: UILabel!

    private var loadedView: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        let nib = UINib(nibName: "ProductListItemView", bundle: .main)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }

        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        loadedView = view

        setupUI()
    }

    private func setupUI() {
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true

        productImageView.layer.cornerRadius = 10
        productImageView.clipsToBounds = true
        productImageView.contentMode = .scaleAspectFill

        discountBadgeLabel.layer.cornerRadius = 8
        discountBadgeLabel.clipsToBounds = true
        discountBadgeLabel.isHidden = true
    }

    func prepareForReuse() {
        productImageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        priceLabel.text = nil
        discountBadgeLabel.text = nil
        discountBadgeLabel.isHidden = true
    }

    func configure(with product: Product) {
        titleLabel.text = product.title
        subtitleLabel.text = product.description
        priceLabel.text = "\(product.price) TL"

        let disc = Int(product.discountPercentage.rounded())
        if disc > 0 {
            discountBadgeLabel.isHidden = false
            discountBadgeLabel.text = "%\(disc)"
        } else {
            discountBadgeLabel.isHidden = true
        }

        // Görsel yüklemeyi sonraki adımda ekleriz (cache’li)
        // product.thumbnail
    }
}
