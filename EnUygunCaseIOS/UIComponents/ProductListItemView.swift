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
    @IBOutlet private weak var oldPriceLabel: UILabel!

    private static let imageCache = NSCache<NSString, UIImage>()
    private var imageTask: URLSessionDataTask?

    override init(frame: CGRect) {
        super.init(frame: frame)
        let nib = UINib(nibName: "ProductListItemView", bundle: .main)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }

        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)

        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true

        productImageView.layer.cornerRadius = 10
        productImageView.clipsToBounds = true
        productImageView.contentMode = .scaleAspectFill

        oldPriceLabel.isHidden = true
    }

    func prepareForReuse() {
        imageTask?.cancel()
        imageTask = nil

        productImageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        priceLabel.text = nil
        oldPriceLabel.attributedText = nil
        oldPriceLabel.isHidden = true
    }

    func configure(with product: Product) {
        titleLabel.text = product.title
        subtitleLabel.text = product.description ?? ""
        priceLabel.text = "\(product.price) TL"

        let discount = product.discountPercentage ?? 0
        if discount > 0 {
            let current = Double(product.price)
            let old = current / (1.0 - (discount / 100.0))

            let oldText = String(format: "%.0f TL", old)
            oldPriceLabel.attributedText = NSAttributedString(
                string: oldText,
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue
                ]
            )
            oldPriceLabel.isHidden = false
        } else {
            oldPriceLabel.isHidden = true
            oldPriceLabel.attributedText = nil
        }

        loadImage(from: product.thumbnail)
    }

    // MARK: - Image Loading

    private func loadImage(from urlString: String?) {
        // Eski task varsa iptal
        imageTask?.cancel()
        imageTask = nil

        productImageView.image = nil

        guard let urlString, !urlString.isEmpty, let url = URL(string: urlString) else {
            return
        }

        let key = urlString as NSString
        if let cached = Self.imageCache.object(forKey: key) {
            productImageView.image = cached
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self else { return }
            if let error = error as NSError?, error.code == NSURLErrorCancelled { return }

            guard let data, let image = UIImage(data: data) else { return }

            Self.imageCache.setObject(image, forKey: key)

            DispatchQueue.main.async {
                self.productImageView.image = image
            }
        }

        imageTask = task
        task.resume()
    }
}
