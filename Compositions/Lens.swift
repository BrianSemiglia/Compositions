//
//  Lens.swift
//  Compositions
//
//  Created by Brian Semiglia on 8/2/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import Foundation

struct Lens<A, B> {
    let get: (A) -> B
    let set: (B, A) -> [A]
    init(get: @escaping (A) -> B, set: @escaping (B, A) -> [A] = { _, _ in [] }) {
        self.get = get
        self.set = set
    }
}

extension Lens {

    static func zip<B1, B2>(
        _ a: Lens<A, B1>,
        _ b: Lens<A, B2>
    ) -> Lens<A, (B1, B2)> where B == (B1, B2) { return
        Lens<A, (B1, B2)>(
            get: {(
                a.get($0),
                b.get($0)
            )},
            set: { parts, whole in
                a.set(parts.0, whole) +
                b.set(parts.1, whole)
            }
        )
    }

    static func zip<B1, B2, B3>(
        _ a: Lens<A, B1>,
        _ b: Lens<A, B2>,
        _ c: Lens<A, B3>
    ) -> Lens<A, (B1, B2, B3)> where B == (B1, B2, B3) { return
        Lens<A, (B1, B2, B3)>(
            get: { (
                a.get($0),
                b.get($0),
                c.get($0)
            ) },
            set: { parts, whole in
                a.set(parts.0, whole) +
                b.set(parts.1, whole) +
                c.set(parts.2, whole)
            }
        )
    }

    static func zip<B1, B2, B3, B4>(
        _ a: Lens<A, B1>,
        _ b: Lens<A, B2>,
        _ c: Lens<A, B3>,
        _ d: Lens<A, B4>
    ) -> Lens<A, (B1, B2, B3, B4)> where B == (B1, B2, B3, B4) { return
        Lens<A, (B1, B2, B3, B4)>(
            get: { (
                a.get($0),
                b.get($0),
                c.get($0),
                d.get($0)
            ) },
            set: { parts, whole in
                a.set(parts.0, whole) +
                b.set(parts.1, whole) +
                c.set(parts.2, whole) +
                d.set(parts.3, whole)
            }
        )
    }

    static func zip<B1, B2, B3, B4, B5>(
        _ a: Lens<A, B1>,
        _ b: Lens<A, B2>,
        _ c: Lens<A, B3>,
        _ d: Lens<A, B4>,
        _ e: Lens<A, B5>
    ) -> Lens<A, (B1, B2, B3, B4, B5)> where B == (B1, B2, B3, B4, B5) { return
        Lens<A, (B1, B2, B3, B4, B5)>(
            get: { (
                a.get($0),
                b.get($0),
                c.get($0),
                d.get($0),
                e.get($0)
            ) },
            set: { parts, whole in
                a.set(parts.0, whole) +
                b.set(parts.1, whole) +
                c.set(parts.2, whole) +
                d.set(parts.3, whole) +
                e.set(parts.4, whole)
            }
        )
    }

    static func map<A, B, C>(_ lens: Lens<A, B>, _ f: @escaping (A, B) -> C) -> Lens<A, C> { return
        Lens<A, C>(
            get: { s in f(s, lens.get(s)) },
            set: { part, whole in lens.set(lens.get(whole), whole) }
        )
    }

    func map<C>(_ f: @escaping (A, B) -> C) -> Lens<A, C> { return
        Lens.map(self, f)
    }

    func prefixed(with prefix: A) -> Lens<A, B> { return
        Lens(
            get: get,
            set: { b, a in [prefix] + self.set(b, a) }
        )
    }
}
