//
//  AsyncNode.swift
//  Compositions
//
//  Created by Brian Semiglia on 3/16/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift

struct AsyncNode<A, B> {
    private var cache: A?
    let initial: A
    let values: Observable<(A, Observable<B>)>
    let callbacks: Observable<B>
    
    init(initial: A, values: Observable<(A, Observable<B>)>, callbacks: Observable<B>) {
        self.initial = initial
        self.values = values.startWith((initial, .never()))
        self.callbacks = callbacks
    }
    
    func map<C>(_ f: @escaping (A) -> C) -> AsyncNode<C, B> {
        return AsyncNode<C, B>(
            initial: f(initial),
            values: values.map { (f($0.0), $0.1) },
            callbacks: callbacks
        )
    }
    
    func zip<Y, Z>(b: AsyncNode<Y, B>, f: @escaping (A, Y) -> Z) -> AsyncNode<Z, B> {
        return AsyncNode.zip(
            a: self,
            b: b,
            f: f
        )
    }
    
    static func zip<A, B, C, D>(
        a: AsyncNode<A, D>,
        b: AsyncNode<B, D>,
        f: @escaping (A, B) -> C
    ) -> AsyncNode<C, D> { return
        AsyncNode<C, D>(
            initial: f(a.initial, b.initial),
            values: Observable
                .combineLatest(a.values, b.values)
                .map { a in (
                    f(a.0.0, a.1.0),
                    Observable.merge(
                        a.1.1,
                        a.0.1
                    )
                )}
            ,
            callbacks: .merge(a.callbacks, b.callbacks)
        )
    }
}

extension Collection {    
    func zipped<A, B>(_ f: @escaping ([A], A) -> [A]) -> AsyncNode<[A], B> where Element == AsyncNode<A, B> {
        print(self.count)
        return reduce(
            AsyncNode<[A], B>(
                initial: [],
                values: .just(([], .never())),
                callbacks: .never()
            )
        ) { a, b in
            return a.zip(b: b, f: f)
        }
    }
}
