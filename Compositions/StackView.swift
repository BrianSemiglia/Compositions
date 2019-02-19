//
//  StackView.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/16/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxGesture

extension CGFloat {
    enum Axis: Equatable {
        case vertical(CGFloat)
        case horizontal(CGFloat)
        func length() -> CGFloat {
            switch self {
            case let .vertical(x): return x
            case let .horizontal(x): return x
            }
        }
    }
}

func + (left: CGFloat.Axis, right: UIView) -> UIStackView {
    let x = UIStackView()
    switch left {
    case .vertical: x.axis = .vertical
    case .horizontal: x.axis = .horizontal
    }
    switch left {
    case let .horizontal(length):
        x.bounds = CGRect(
            origin: .zero,
            size: CGSize(
                width: right.frame.size.width + length,
                height: right.frame.size.height
            )
        )
    case let .vertical(length):
        x.bounds = CGRect(
            origin: .zero,
            size: CGSize(
                width: right.frame.size.width,
                height: right.frame.size.height + length
            )
        )
    }
    switch left {
    case let .horizontal(length):
        x.addArrangedSubview(
            UIView() + CGSize(width: length, height: 0)
        )
    case let .vertical(length):
        x.addArrangedSubview(
            UIView() + CGSize(width: 0, height: length)
        )
    }
    x.addArrangedSubview(right)
    return x
}

func + (left: UIStackView, right: UIView) -> UIStackView {
    left.addArrangedSubview(right)
    return left
}

func + (left: UIStackView, right: [UIView]) -> UIStackView {
    right.forEach {
        left.addArrangedSubview($0)
    }
    left.frame = CGRect(
        origin: .zero,
        size: left.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    )
    return left
}

func + <T>(left: Node<UIView, T>, right: CGFloat.Axis) -> Node<UIStackView, T> {
    return Node(
        value: left.value + right,
        callback: left.callback
    )
}

func + (left: UIView, right: CGFloat.Axis) -> UIStackView {
    let x = UIStackView()
    switch right {
    case .vertical: x.axis = .vertical
    case .horizontal: x.axis = .horizontal
    }
    switch right {
    case let .horizontal(length):
        x.bounds = CGRect(
            origin: .zero,
            size: CGSize(
                width: left.frame.size.width + length,
                height: left.frame.size.height
            )
        )
    case let .vertical(length):
        x.bounds = CGRect(
            origin: .zero,
            size: CGSize(
                width: left.frame.size.width,
                height: left.frame.size.height + length
            )
        )
    }
    x.addArrangedSubview(left)
    switch right {
    case let .horizontal(length):
        x.addArrangedSubview(
            UIView() + CGSize(width: length, height: 0)
        )
    case let .vertical(length):
        x.addArrangedSubview(
            UIView() + CGSize(width: 0, height: length)
        )
    }
    return x
}

func + (left: UIStackView, right: NSLayoutConstraint.Axis) -> UIStackView {
    left.axis = right
    return left
}

func + <T>(left: UIStackView, right: Node<UIView, T>) -> Node<UIStackView, T> {
    return Node(
        value: left + right.value,
        callback: right.callback
    )
}

func + <T>(left: Node<UIStackView, T>, right: Node<UIView, T>) -> Node<UIStackView, T> {
    return Node(
        value: left.value + right.value,
        callback: Observable.merge(left.callback, right.callback)
    )
}

func + <T>(left: Node<UIStackView, T>, right: Observable<T>) -> Node<UIStackView, T> {
    return Node(
        value: left.value,
        callback: Observable.merge(left.callback, right)
    )
}

func + (left: UIStackView, right: Observable<Void>) -> Node<UIStackView, Void> {
    return Node(
        value: left,
        callback: left.rx.tapGesture().when(.recognized).flatMap { _ in right }
    )
}
