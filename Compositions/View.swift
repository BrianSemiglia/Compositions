//
//  View.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/16/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

func + (left: UIView, right: CGSize) -> UIView {
    left.bounds = CGRect(origin: .zero, size: right)
    return left
}

func + (left: CGSize, right: UIColor) -> UIView {
    return right + left
}

func + (left: UIColor, right: CGSize) -> UIView {
    let x = UIView()
    x.bounds = CGRect(origin: .zero, size: right)
    x.backgroundColor = left
    return x
}

func + (left: [UIView], right: CGSize) -> UIView {
    if (left.reduce(0) { $0 + $1.bounds.size.height }) > right.height {
        return Table(model: left) + right
    } else {
        return (UIStackView() + left) + right
    }
}

func + (left: [UIView], right: CGSize) -> UIViewController {
    let x = UIViewController()
    let y: UIView = left + right
    x.view.addSubview(y)
    y.frame = x.view.bounds
    return x
}

func + <T>(left: UIView, right: Observable<T>) -> Node<UIView, T> {
    left.isUserInteractionEnabled = true
    return Node(
        value: left,
        callback: left
            .rx
            .tapGesture()
            .when(.recognized)
            .flatMap { _ in
                right
            }
    )
}
