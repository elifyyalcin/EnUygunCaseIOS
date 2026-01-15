//
//  BasketItemCell.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 15.01.2026.
//

import Foundation
import UIKit

final class BasketItemCell: UITableViewCell {

    static let reuseID = "BasketItemCell"

    @IBOutlet private weak var cardView: UIView!
    @IBOutlet private weak var productImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var oldPriceLabel: UILabel!

    @IBOutlet private weak var minusButton: UIButton!
    @IBOutlet private weak var qtyLabel: UILabel!
    @IBOutlet private weak var plusButton: UIButton!
    @IBOutlet private weak var trashButton: UIButton!

    var onTapPlus: (() -> Void)?
    var onTapMinus: (() -> Void)?
    var onTapTrash: (() -> Void)?

    private var imageTask: URLSessionDataTask?

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        backgroundColor = .clear

        cardView.backgroundColor = UIColor.systemGray5
        cardView.layer.cornerRadius = 14
        cardView.layer.masksToBounds = true

        productImageView.contentMode = .scaleAspectFit
        productImageView.layer.cornerRadius = 8
        productImageView.clipsToBounds = true

        minusButton.layer.cornerRadius = 6
        plusButton.layer.cornerRadius = 6

        trashButton.setImage(UIImage(systemName: "trash"), for: .normal)
        trashButton.tintColor = .systemRed

        minusButton.addTarget(self, action: #selector(didTapMinus), for: .touchUpInside)
        plusButton.addTarget(self, action: #selector(didTapPlus), for: .touchUpInside)
        trashButton.addTarget(self, action: #selector(didTapTrash), for: .touchUpInside)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        productImageView.image = nil
        onTapPlus = nil
        onTapMinus = nil
        onTapTrash = nil
        oldPriceLabel.attributedText = nil
        oldPriceLabel.isHidden = true
        qtyLabel.text = nil
    }

    func configure(line: BasketLine) {
        titleLabel.text = line.product.title
        qtyLabel.text = "\(line.quantity)"

        priceLabel.text = Money.tl(line.product.price)

        if let old = line.product.oldPrice {
            oldPriceLabel.isHidden = false
            oldPriceLabel.attributedText = NSAttributedString(
                string: Money.tl(old),
                attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
            )
        } else {
            oldPriceLabel.isHidden = true
            oldPriceLabel.attributedText = nil
        }

        if let urlStr = line.product.imageURL, let url = URL(string: urlStr) {
            loadImage(url: url)
        }
    }

    private func loadImage(url: URL) {
        imageTask?.cancel()
        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.productImageView.image = img
            }
        }
        imageTask?.resume()
    }

    @objc private func didTapPlus() { onTapPlus?() }
    @objc private func didTapMinus() { onTapMinus?() }
    @objc private func didTapTrash() { onTapTrash?() }
}

