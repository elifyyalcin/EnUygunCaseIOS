//
//  OptionSheetVC.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 16.01.2026.
//

import UIKit

final class OptionSheetVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let titleText: String
    private let options: [String]
    private var selected: String?
    private let onSelect: (String?) -> Void

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    init(title: String,
         options: [String],
         selected: String?,
         onSelect: @escaping (String?) -> Void) {
        self.titleText = title
        self.options = options
        self.selected = selected
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = titleText

        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { options.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let text = options[indexPath.row]
        cell.textLabel?.text = text
        cell.accessoryType = (text == selected) ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let picked = options[indexPath.row]
        selected = picked
        tableView.reloadData()

        onSelect(picked)
        dismiss(animated: true)
    }
}
