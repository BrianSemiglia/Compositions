//
//  AlertViewController.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/17/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit
import RxSwift

private func example() {
    let alert = UIAlertController(
        title: "title",
        message: "message",
        preferredStyle: .alert
    )
    let yes = "Yes" + UIAlertAction.Style.default + Observable.just("yes")
    let no = "No" + UIAlertAction.Style.default + Observable.just("no")
    let cancel = "Cancel" + UIAlertAction.Style.default + Observable.just("cancel")
    _ = alert + [yes, no, cancel]
}

func + (left: UIAlertController, right: UIAlertAction) -> UIAlertController {
    return left.with(actions: [right])
}

func + <T>(left: UIAlertController, right: Node<UIAlertAction, T>) -> Node<UIAlertController, T> {
    return Node(
        value: left.with(actions: [right.value]),
        callback: right.callback
    )
}

func + <T>(left: UIAlertController, right: [Node<UIAlertAction, T>]) -> Node<UIAlertController, T> {
    return Node(
        value: left.with(actions: right.map { $0.value }),
        callback: Observable.merge(
            right.map { $0.callback }
        )
    )
}

func + <T>(left: Node<UIAlertController, T>, right: Node<UIAlertAction, T>) -> Node<UIAlertController, T> {
    return left + [right]
}

func + <T>(left: Node<UIAlertController, T>, right: [Node<UIAlertAction, T>]) -> Node<UIAlertController, T> {
    return Node(
        value: left.value.with(actions: right.map { $0.value }),
        callback: Observable.merge(
            right.map { $0.callback } + [left.callback]
        )
    )
}

func +<T>(left: String, right: UIAlertAction.Style) -> (Observable<T>) -> Node<UIAlertAction, T> {
    return { observable in
        let publish = PublishSubject<Void>()
        // let x = observable.share()
        // Observable.just(()).flatMap { observable }.share()
        return Node(
            value: UIAlertAction(
                title: left,
                style: right,
                handler: { _ in
//                    let n = Observable.just(()).flatMap { x }
                    publish.on(.next(()))
                    publish.on(.completed)
                }
            ),
            callback: publish.flatMap { _ in observable } //
        )
    }
}

func + <T>(left: (Observable<T>) -> Node<UIAlertAction, T>, right: Observable<T>) -> Node<UIAlertAction, T> {
    return left(right)
}

extension UIAlertController {
    func with(actions: [UIAlertAction]) -> UIAlertController {
        actions.forEach { addAction($0) }
        return self
    }
}
