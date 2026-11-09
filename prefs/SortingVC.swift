// SortingVC.swift
// 对应原版：SortAppVC / SortToolsVC（UITableViewController）
// 拖动排序，结果写入 allApps / selectedTools 数组。

import UIKit

public final class FVSortAppVC: UITableViewController {
    public var plistKey: String = FVKey.allApps
    private var items: [String] = []

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "应用排序"
        items = FVPrefsStore.shared.array(plistKey, as: String.self)
        if items.isEmpty {
            items = FVAppHelper.installedApps().map { $0.id }
        }
        tableView.setEditing(true, animated: false)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(done))
    }

    @objc private func done() {
        FVPrefsStore.shared.set(items, for: plistKey)
        navigationController?.popViewController(animated: true)
    }

    public override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    public override func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "cell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let bid = items[indexPath.row]
        cell.textLabel?.text = FVAppHelper.icon(for: bid) != nil
            ? (FVAppHelper.installedApps().first { $0.id == bid }?.name ?? bid) : bid
        cell.detailTextLabel?.text = bid
        cell.imageView?.image = FVAppHelper.icon(for: bid)
        return cell
    }
    public override func tableView(_ tv: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool { true }
    public override func tableView(_ tv: UITableView,
                                   moveRowAt source: IndexPath, to destination: IndexPath) {
        let it = items.remove(at: source.row)
        items.insert(it, at: destination.row)
    }
    public override func tableView(_ tv: UITableView,
                                   editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle { .none }
    public override func tableView(_ tv: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool { false }
}

public final class FVSortToolsVC: UITableViewController {
    public var plistKey: String = FVKey.selectedTools
    private var items: [FVToolAction] = []

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "工具排序"
        let raw = FVPrefsStore.shared.array(plistKey, as: Int.self)
        items = raw.isEmpty ? FVToolAction.allCases : raw.compactMap { FVToolAction(rawValue: $0) }
        tableView.setEditing(true, animated: false)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(done))
    }

    @objc private func done() {
        FVPrefsStore.shared.set(items.map { $0.rawValue }, for: plistKey)
        navigationController?.popViewController(animated: true)
    }

    public override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    public override func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "cell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let a = items[indexPath.row]
        cell.textLabel?.text = a.title
        cell.imageView?.image = UIImage(systemName: a.symbolName)
        return cell
    }
    public override func tableView(_ tv: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool { true }
    public override func tableView(_ tv: UITableView,
                                   moveRowAt source: IndexPath, to destination: IndexPath) {
        let it = items.remove(at: source.row)
        items.insert(it, at: destination.row)
    }
    public override func tableView(_ tv: UITableView,
                                   editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle { .none }
    public override func tableView(_ tv: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool { false }
}
