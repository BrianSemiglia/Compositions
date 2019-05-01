//
//  Node.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/16/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit
import RxSwift

struct Foo<A, B> { // profunctor optics
    let x: (A) -> B // A -> (((A) -> B) -> C) -> D) -> D
    let y: (B) -> A // [(Void) -> T, (Void) -> T] -> ((Void) -> T)
}

/*

 let a =
    Observable<Node<UIImageView>>
        request1
            .map(toImageView)
            .startWith(placeholder)
            .map(toNode)

 let b =
    Observable<Node<UIImageView>>
        request2
            .map(toImageView)
            .startWith(placeholder)
            .map(toNode)

 let c =
    Observable<Node<Table>>
        .merge(a, b)
        .scan([Hash: Element]) { $0 + [$1] } // accumulate, replacing existing hashed
        .map { $0.reduce(UIView(), +) }

 [
 (p, p),
 (1, p) | (p, 2) ,
 (1, 2)
 ]

 given a Node
    next
    until Element.size > Context.size

 example:
    node(context.size) // innerNodes.accumulatedUntil { $0.placeholder > context.size }

 example:
    list                                                // Observable<[URL]>
        .map {
            $0                                          // [URL]
            .map { url / Image.self + size }            // [Node<UIImageView>]
            .map { nodes + UIScreen.main.bounds.size }  // Node<Table>
        }                                               // Observable<Node<Table>>

 example:
    list
        .map { url / Image.self + size }
        .map {
            $0.addedUntil { $0.size > UIScreen.main.bounds.size } // not needed as contents not yet rendered
        }

 */

//struct AsyncNode<A, B> {
//    private var cache: A?
//    let initial: A // change to (A, Observable<B>)
//    let values: Observable<(A, Observable<B>)>
//    let callbacks: Observable<B>
//
//    init(initial: A, values: Observable<(A, Observable<B>)>, callbacks: Observable<B>) {
//        self.initial = initial
//        self.values = values.startWith((initial, .never()))
//        self.callbacks = callbacks
//    }
//
////    func cacheMap<C>(_ f: @escaping (C?, A) -> C) -> AsyncNode_<C, B> {
////        return AsyncNode_<C, B>(
////            initial: f(nil, initial),
////            values: values
////                .scan((Optional<C>.none, Observable<B>.never())) { sum, next in
////                    (f(sum.0, next.0), next.1)
////                }
////                .map { ($0.0!, $0.1) }
////            ,
////            callbacks: callbacks
////        )
////    }
//
//    func map<C>(_ f: @escaping (A) -> C) -> AsyncNode<C, B> {
//        return AsyncNode<C, B>(
//            initial: f(initial),
//            values: values.map { (f($0.0), $0.1) },
//            callbacks: callbacks
//        )
//    }
//
//    func zip<Y, Z>(b: AsyncNode<Y, B>, f: @escaping (A, Y) -> Z) -> AsyncNode<Z, B> {
//        return AsyncNode.zip(
//            a: self,
//            b: b,
//            f: f
//        )
//    }
//
//    static func zip<A, B, C, D>(a: AsyncNode<A, D>, b: AsyncNode<B, D>, f: @escaping (A, B) -> C) -> AsyncNode<C, D> {
//
//        let k = Observable
//            .combineLatest(a.values, b.values)
//            .map { a in (
//                f(a.0.0, a.1.0),
//                Observable.merge(
//                    a.1.1,
//                    a.0.1
//                )
//                // [(a), (a, (a, b)), (a, (a, b, (a, b, c))]
//                // [(c, (b, (a, n))), (b, (a, n)), (a, n)]
//            )}
//
////        let h = Observable
////            .zip(a.values, b.values)
////            .map { a in (
////                f(a.0.0, a.1.0),
////                Observable.merge(a.0.1, a.1.1)
////            )}
////        let g = a
////            .values // need to be able to combine observables of different types
////            .withLatestFrom(b.values) { ($0, $1) }
////            .map { a in
////                (
////                    f(a.0.0, a.1.0),
////                    Observable.merge(a.0.1, a.1.1)
////                )
//////                Observable.combineLatest(a.0.0, a.1.0).map(f)
////            }
////        let n = Observable.combineLatest(
////            a.values.map { $0.0 },//.startWith(a.initial),
////            b.values.map { $0.0 }//.startWith(b.initial)
////        ).map(f)
////        let z = Observable
////            .combineLatest(
////                a.values.map { $0.1 },
////                b.values.map { $0.1 }
////            )
////            .flatMap { Observable.merge($0, $1) }
////        let p = n.map {(
////            $0,
////            z
//////            Observable.merge(
//////                a.values.flatMap { $0.1 },
//////                b.values.flatMap { $0.1 }
//////            )
////        )}
//        return AsyncNode<C, D>(
//            initial: f(a.initial, b.initial),
//            values: k
////                .debug("zipping", trimOutput: false)
////                .startWith((
////                    f(a.initial, b.initial),
////                    Observable.merge(a.callbacks, b.callbacks)
////                ))
//            ,
//            callbacks: .merge(a.callbacks, b.callbacks)
//        )
//    }
//}

struct AsyncNodePrevious<A, B> {
    let initial: A
    let values: Observable<A>
    let callbacks: Observable<B>
    let dispose: DisposeBag
    init(initial: A, value: Observable<A>, callback: Observable<B>, dispose: DisposeBag = DisposeBag()) {
        self.initial = initial
        self.values = value.share().startWith(initial)
        self.callbacks = callback
        self.dispose = dispose
    }
    func map<T>(_ f: @escaping (A) -> T) -> AsyncNodePrevious<T, B> {
        return AsyncNodePrevious<T, B>(
            initial: f(initial),
            value: values.map(f),
            callback: callbacks
        )
    }
    // combineLatest(node, node) { [$0, $1] + size }
    func flatMap<T>(_ f: @escaping (A) -> AsyncNodePrevious<T, B>) -> AsyncNodePrevious<T, B> {
//        let a = values.map { f($0).initial }
//        let b = f(initial).values
//        let c = values.flatMap { f($0).values }
//
//        // need transformation from T.value + A.value
//        // a.latest|a.placholder + b.latest|b.placeholder
//
//        let z = Observable.combineLatest(
//            Observable.merge(values, .just(initial)),
//            Observable.merge(values.flatMap { f($0).values }, f(initial).values)
//        )
//
        return AsyncNodePrevious<T, B>(
            initial: f(initial).initial,
            // either: A + placholder, B + placeholder, A + B
            value: values.flatMap { f($0).values },
            callback: .merge(
                callbacks,
                f(initial).callbacks
            )
        )
    }

    func zip<Y, Z>(b: AsyncNodePrevious<Y, B>, f: @escaping (A, Y) -> Z) -> AsyncNodePrevious<Z, B> {
        return AsyncNodePrevious.zip(
            a: self,
            b: b,
            f: f
        )
    }

    static func zip<A, B, C, D>(a: AsyncNodePrevious<A, D>, b: AsyncNodePrevious<B, D>, f: @escaping (A, B) -> C) -> AsyncNodePrevious<C, D> {
        return AsyncNodePrevious<C, D>(
            initial: f(a.initial, b.initial),
            value: Observable.combineLatest(a.values, b.values).map(f),
            callback: Observable.merge(a.callbacks, b.callbacks)
        )
    }
}

extension Collection {
    func zipped<A, B>(_ f: @escaping ([A], A) -> [A]) -> AsyncNodePrevious<[A], B> where Element == AsyncNodePrevious<A, B> {
        return reduce(
            AsyncNodePrevious<[A], B>(
                initial: [],
                value: .just([]),
                callback: .never()
            )
        ) { a, b in
            return a.zip(b: b, f: f)
        }
    }

//    func zipped<A, B>(_ f: @escaping ([A], A) -> [A]) -> AsyncNode<[A], B> where Element == AsyncNode<A, B> {
//        print(self.count)
//        return reduce(
//            AsyncNode<[A], B>(
//                initial: [],
//                values: .just(([], .never())),
//                callbacks: .never()
//            )
//        ) { a, b in
//            return a.zip(b: b, f: f)
//        }
//    }
}

func + <A, B, C, D>(left: AsyncNodePrevious<A, D>, right: AsyncNodePrevious<B, D>) -> (@escaping (A, B) -> C) -> AsyncNodePrevious<C, D> {
    return { f in
        return left.zip(b: right, f: f)
    }
}

func + <A, B, C, D>(left: (@escaping (A, B) -> C) -> AsyncNodePrevious<C, D>, right: (@escaping (A, B) -> C)) -> AsyncNodePrevious<C, D> {
    return left(right)
}

struct Node<A, C> {
    let value: A
    let callback: Observable<C>
    func map<T>(_ f: (A) -> T) -> Node<T, C> {
        return Node<T, C>(
            value: f(value),
            callback: callback
        )
    }
    func flatMap<T>(_ f: (A) -> Node<T, C>) -> Node<T, C> {
        let x = f(value)
        return Node<T, C>(
            value: x.value,
            callback: .merge(
                callback,
                x.callback
            )
        )
    }
    func mapCallback<U>(f: @escaping (C) -> U) -> Node<A, U> {
        return Node<A, U>(
            value: value,
            callback: callback.map(f)
        )
    }
}

private func example() {
//    let a = Node(value: "string", callback: Observable<Void>.never())
//    let b = Node(value: UIColor.Text.foreground(.red), callback: Observable<Void>.never())
//    let c = (a + b)(+)
//    let d = a + (+) + b
//    let z = a transform(/) b
//    let z = (a, b) + transform(/)
//    let z = (a + b) / c
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
//
//func + <A, B, C, D>(left: Node<A, D>, right: @escaping (A, B) -> C) -> (Node<B, D>) -> Node<C, D> {
//    fatalError()
//}
//
//func + <B, C, D>(left: (Node<B, D>) -> Node<C, D>, right: Node<B, D>) -> Node<C, D> {
//    fatalError()
//}
//
//
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
//
//func + <A, B, C, D>(left: (@escaping (A, B) -> C) -> Node<C, D>, right: @escaping (A, B) -> C) -> Node<C, D> {
//    return left(right)
//}
