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
    
    /*
     As nodes become relevant, they subscribe. Subscribing causes entire tree to re-execute?
     Probably not: node of nodes is lazy and isolated?
     */
    
    let initial: A
    let subsequent: Observable<(A, Observable<B>)>
    
    init(initial: A, subsequent: Observable<(A, Observable<B>)>) {
        self.initial = initial
        self.subsequent = subsequent.startWith((initial, .never()))
    }
    
    func map<C>(_ f: @escaping (A) -> C) -> AsyncNode<C, B> {
        return AsyncNode<C, B>(
            initial: f(initial),
            subsequent: subsequent.map { (f($0.0), $0.1) }
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
            subsequent: Observable
                .combineLatest(a.subsequent, b.subsequent)
                .map { a in (
                    f(a.0.0, a.1.0),
                    Observable.merge(
                        a.1.1,
                        a.0.1
                    )
                )}
        )
    }
}

extension Collection {    
    func zipped<A, B>(_ f: @escaping ([A], A) -> [A]) -> AsyncNode<[A], B> where Element == AsyncNode<A, B> {
        print(self.count)
        return reduce(
            AsyncNode<[A], B>(
                initial: [],
                subsequent: .just(([], .never()))
            )
        ) { a, b in
            return a.zip(
                b: b,
                f: f
            )
        }
    }
}
