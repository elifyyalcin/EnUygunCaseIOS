//
//  FavoriteItemCell.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 16.01.2026.
//

import UIKit

final class FavoriteItemCell: UICollectionViewCell {

    static let reuseID = "FavoriteItemCell"

    @IBOutlet private weak var cardView: UIView!
    @IBOutlet private weak var productImageView: UIImageView!
    @IBOutlet private weak var heartButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var plusButton: UIButton!

    var onTapHeart: (() -> Void)?
    var onTapPlus: (() -> Void)?

    private var imageTask: URLSessionDataTask?

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.backgroundColor = .clear

        cardView.backgroundColor = UIColor.systemGray5
        cardView.layer.cornerRadius = 18
        cardView.layer.masksToBounds = true

        productImageView.contentMode = .scaleAspectFit
        productImageView.clipsToBounds = true

        heartButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        heartButton.tintColor = .systemRed

        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1

        priceLabel.font = .systemFont(ofSize: 16, weight: .bold)

        heartButton.addTarget(self, action: #selector(didTapHeart), for: .touchUpInside)
        plusButton.addTarget(self, action: #selector(didTapPlus), for: .touchUpInside)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        productImageView.image = nil
        onTapHeart = nil
        onTapPlus = nil
    }

    func configure(product: Product) {
        titleLabel.text = product.title
        subtitleLabel.text = product.description
        priceLabel.text = Money.tl(product.price)

        if let urlStr = product.images?.first, let url = URL(string: urlStr) {
            loadImage(url: url)
        }
    }

    private func loadImage(url: URL) {
        imageTask?.cancel()
        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async { self?.productImageView.image = img }
        }
        imageTask?.resume()
    }

    @objc private func didTapHeart() { onTapHeart?() }
    @objc private func didTapPlus() { onTapPlus?() }
}

