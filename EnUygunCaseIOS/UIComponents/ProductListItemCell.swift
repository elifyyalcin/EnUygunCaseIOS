//
//  ProductListItemCell.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 14.01.2026.
//

import UIKit

final class ProductListItemCell: UITableViewCell {

    static let reuseID = "ProductListItemCell"

    private let itemView = ProductListItemView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        selectionStyle = .none
        contentView.backgroundColor = .clear

        itemView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(itemView)

        NSLayoutConstraint.activate([
            itemView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            itemView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            itemView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            itemView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        itemView.prepareForReuse()
    }

    func configure(product: Product) {
        itemView.configure(with: product)
    }
}
