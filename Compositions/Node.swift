//
//  Node.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/16/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit
import RxSwift

struct Node<A, C> {
    let value: A
    let callback: Observable<C>
}

private func example() {
    let a = Node(value: "string", callback: Observable<Void>.never())
    let b = Node(value: UIColor.Text.foreground(.red), callback: Observable<Void>.never())
    let c = (a + b) + (+)
    let d = a + (+) + b
    // let z = a transform(/) b
    // let z = (a, b) + transform(/)
    // let z = (a + b) / c

}

//protocol Foo {
//    associatedtype Other
//    associatedtype New
//    static func +(left: Self, right: Other) -> New
//}
//
//func + <A: Foo, B, C, D>(left: Node<A, D>, right: Node<B, D>) -> Node<C, D> where A.Other == B, A.New == C {
//    return Node(
//        value: left.value + right.value,
//        callback: Observable.merge(
//            left.callback,
//            right.callback
//        )
//    )
//}

func + <A, B, C, D>(left: Node<A, D>, right: @escaping (A, B) -> C) -> (Node<B, D>) -> Node<C, D> {
    fatalError()
}

func + <B, C, D>(left: (Node<B, D>) -> Node<C, D>, right: Node<B, D>) -> Node<C, D> {
    fatalError()
}


func + <A, B, C, D>(left: Node<A, D>, right: Node<B, D>) -> (@escaping (A, B) -> C) -> Node<C, D> {
    return { f in
        Node(
            value: f(
                left.value,
                right.value
            ),
            callback: Observable.merge(
                left.callback,
                right.callback
            )
        )
    }
}

func + <A, B, C, D>(left: (@escaping (A, B) -> C) -> Node<C, D>, right: @escaping (A, B) -> C) -> Node<C, D> {
    return left(right)
}
