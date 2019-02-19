//
//  TableView.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/16/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

final class Table: UITableView, UITableViewDataSource {
    let cells: [UIView]
    init(model: [UIView]) {
        cells = model
        super.init(
            frame: .zero,
            style: .plain
        )
        dataSource = self
    }
    @available(*, unavailable) required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell() + cells[indexPath.row]
    }
}

func + (left: UITableViewCell, right: UIView) -> UITableViewCell {
    left.contentView.addSubview(right)
    right.translatesAutoresizingMaskIntoConstraints = false
    right.topAnchor.constraint(equalTo: left.contentView.topAnchor, constant: 0).isActive = true
    right.bottomAnchor.constraint(equalTo: left.contentView.bottomAnchor, constant: 0).isActive = true
    right.leadingAnchor.constraint(equalTo: left.contentView.leadingAnchor, constant: 0).isActive = true
    right.trailingAnchor.constraint(equalTo: left.contentView.trailingAnchor, constant: 0).isActive = true
    return left
}
