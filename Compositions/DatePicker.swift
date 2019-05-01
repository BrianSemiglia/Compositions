//
//  DatePicker.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/20/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

private func testNavigationBar() -> Node<UINavigationController, String> {
    let a = UIBarButtonItem.Model(title: "Left", style: .plain) + Observable.just("+")
    let b = UIBarButtonItem.Model(title: "Right", style: .plain) + Observable.just("-")
    let c: UIViewController = .red + UIScreen.main.bounds.size
    let d = a + "Title" + b + c
    return d
}

extension UIBarButtonItem {
    struct Model {
        let title: String
        let style: UIBarButtonItem.Style
    }
}

extension UINavigationBar {
    struct Model<T> {
        let left: [Node<UIBarButtonItem.Model, T>]
        let title: String
        let right: [Node<UIBarButtonItem.Model, T>]
    }
}

func + <T>(left: UIBarButtonItem.Model, right: Observable<T>) -> (Node<UIBarButtonItem.Model, T>) {
    return Node(
        value: left,
        callback: right
    )
}

func + <T>(left: Node<UIBarButtonItem.Model, T>, right: String) -> (Node<UIBarButtonItem.Model, T>) -> Node<UINavigationBar.Model<T>, T> {
    return { item in
        return [left] + right + [item]
    }
}

func + <T>(
    left: (Node<UIBarButtonItem.Model, T>) -> Node<UINavigationBar.Model<T>, T>,
    right: Node<UIBarButtonItem.Model, T>) -> Node<UINavigationBar.Model<T>, T> {
    return left(right)
}

func + <T>(left: Node<UIBarButtonItem.Model, T>, right: String) -> ([Node<UIBarButtonItem.Model, T>]) -> Node<UINavigationBar.Model<T>, T> {
    return { items in
        return [left] + right + items
    }
}

func + <T>(left: [Node<UIBarButtonItem.Model, T>], right: String) -> (Node<UIBarButtonItem.Model, T>) -> Node<UINavigationBar.Model<T>, T> {
    return { item in
        return left + right + [item]
    }
}

func + <T>(left: [Node<UIBarButtonItem.Model, T>], right: String) -> ([Node<UIBarButtonItem.Model, T>]) -> Node<UINavigationBar.Model<T>, T> {
    return { items in
        Node(
            value: UINavigationBar.Model(
                left: left,
                title: right,
                right: items
            ),
            callback: Observable.never()
        )
    }
}

func + <T>(
    left: ([Node<UIBarButtonItem.Model, T>]) -> Node<UINavigationBar.Model<T>, T>,
    right: [Node<UIBarButtonItem.Model, T>]) -> Node<UINavigationBar.Model<T>, T> {
    return left(right)
}

func + <T>(left: Node<UINavigationBar.Model<T>, T>, right: UIViewController) -> Node<UINavigationController, T> {
    right.navigationItem.leftBarButtonItems = left.value.left.map {
        UIBarButtonItem(
            title: $0.value.title,
            style: $0.value.style
        )
    }
    right.title = left.value.title
    right.navigationItem.rightBarButtonItems = left.value.right.map {
        UIBarButtonItem(
            title: $0.value.title,
            style: $0.value.style
        )
    }

    return Node(
        value: UINavigationController(rootViewController: right),
        callback: Observable.merge(
            [left.callback]
                + zip(right.navigationItem.leftBarButtonItems!, left.value.left)
                    .map { tuple in tuple.0.rx.tap.flatMap { tuple.1.callback }}
                + zip(right.navigationItem.rightBarButtonItems!, left.value.right)
                    .map { tuple in tuple.0.rx.tap.flatMap { tuple.1.callback }}
        )
    )
}

//func + (left: UIBarButtonItem, right: Observable<Void>) -> Node<UIBarButtonItem, Void> {
//    return Node(
//        value: left,
//        callback: left.rx.tap.flatMap { right }
//    )
//}
//
//func + (left: Observable<Void>, right: UIBarButtonItem) -> Node<UIBarButtonItem, Void> {
//    return Node(
//        value: right,
//        callback: right.rx.tap.flatMap { left }
//    )
//}
//
//func + (left: Node<UIBarButtonItem, Void>, right: UIViewController) -> Node<UIViewController, Void> {
//    return Node(
//        value: left.value + right,
//        callback: left.callback
//    )
//}
//
//func + (left: UIViewController, right: Node<UIBarButtonItem, Void>) -> Node<UIViewController, Void> {
//    return Node(
//        value: left + right.value,
//        callback: right.callback
//    )
//}
//
//func + <T>(left: Node<UIViewController, T>, right: Node<UIBarButtonItem, T>) -> Node<UIViewController, T> {
//    return Node(
//        value: left.value + right.value,
//        callback: right.callback
//    )
//}
//
//func + (left: UIBarButtonItem, right: UIViewController) -> UIViewController {
//    right.navigationItem.leftBarButtonItem = left
//    return right
//}
//
//func + (left: UIViewController, right: UIBarButtonItem) -> UIViewController {
//    left.navigationItem.rightBarButtonItem = right
//    return left
//}

extension UIBarButtonItem {
    convenience init(title: String, style: UIBarButtonItem.Style) {
        self.init(
            title: title,
            style: style,
            target: nil,
            action: nil
        )
    }
}
