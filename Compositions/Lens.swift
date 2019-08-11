//
//  Lens.swift
//  Compositions
//
//  Created by Brian Semiglia on 8/2/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import Foundation

struct Lens<A, B> {

    private let value: A
    let get: () -> B
    let set: () -> [A]

    init(value: A, get: @escaping (A) -> B, set: @escaping (B, A) -> [A] = { _, _ in [] }) {
        let b = get(value)
        self.value = value
        self.get = { b }
        self.set = { set(b, value) }
    }

    init(value: A, get: @escaping (A) -> B, set: @escaping (B, A) -> A) {
        let b = get(value)
        self.value = value
        self.get = { b }
        self.set = { [set(b, value)] }
    }

    func zip<C>(_ other: Lens<A, C>) -> Lens<A, (B, C)> {
        return Lens<A, (B, C)>(
            value: value,
            get: { a in (self.get(), other.get()) },
            set: { _, a in self.set() + other.set() }
        )
    }

    func map<C>(_ f: @escaping (A, B) -> C) -> Lens<A, C> {
        return Lens<A, C>(
            value: value,
            get: { a in f(a, self.get()) },
            set: { _, _ in self.set() }
        )
    }

    func prefixed(with prefix: A) -> Lens<A, B> { return
        Lens(
            value: value,
            get: { _ in self.get() },
            set: { _, _ in [prefix] + self.set() }
        )
    }
}
