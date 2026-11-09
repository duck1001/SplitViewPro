// FVSideBarContentView.swift
// 对应原版：floatingView.FVSideBarContentView（UIView <UICollectionViewDataSource, UICollectionViewDelegate>）
// 字段：collectionView、allData: [String]、gridCellDelegate: FVGridCellDelegate?、selectedIndexPath

import UIKit

public protocol FVGridCellDelegate: AnyObject {
    func gridCellDidSelect(bundleIdentifier: String)
}

public final class FVSideBarContentView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {

    public var collectionView: UICollectionView?
    public var allData: [String] = []
    public weak var gridCellDelegate: FVGridCellDelegate?
    public var selectedIndexPath: IndexPath?

    private let cellID = "FVSiderBarItemCell"

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear

        let lay = UICollectionViewFlowLayout()
        lay.scrollDirection = .vertical
        lay.minimumLineSpacing = 10
        lay.minimumInteritemSpacing = 10

        let cv = UICollectionView(frame: .zero, collectionViewLayout: lay)
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.showsVerticalScrollIndicator = false
        cv.showsHorizontalScrollIndicator = false
        cv.register(FVSiderBarItemCell.self, forCellWithReuseIdentifier: cellID)
        cv.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cv)
        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: topAnchor),
            cv.leadingAnchor.constraint(equalTo: leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: trailingAnchor),
            cv.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        collectionView = cv
    }

    public func setData(_ list: [String]) {
        allData = list
        collectionView?.reloadData()
    }

    public func layoutSubviews(with itemSize: CGSize) {
        if let lay = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            lay.itemSize = itemSize
            lay.invalidateLayout()
        }
    }

    // MARK: - UICollectionViewDataSource / Delegate

    public func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        allData.count
    }

    public func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath)
        if let c = cell as? FVSiderBarItemCell {
            c.configure(bundleIdentifier: allData[indexPath.item])
        }
        return cell
    }

    public func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        gridCellDelegate?.gridCellDidSelect(bundleIdentifier: allData[indexPath.item])
        cv.deselectItem(at: indexPath, animated: true)
    }
}
