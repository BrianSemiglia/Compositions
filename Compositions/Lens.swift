//
//  Lens.swift
//  Compositions
//
//  Created by Brian Semiglia on 8/2/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import Foundation

struct Lens<A, B, C> {
    let constant: C
    let get: (C, A) -> B
    let set: (B, A) -> [A]
    init(constant: C, get: @escaping (C, A) -> B, set: @escaping (B, A) -> [A] = { _, _ in [] }) {
        self.constant = constant
        self.get = get
        self.set = set
    }
    init(constant: C, get: @escaping (C, A) -> B, set: @escaping (B, A) -> A) {
        self.constant = constant
        self.get = get
        self.set = { [set($0, $1)] }
    }
}

extension Lens {

    static func zip<B1, B2, B3, B4>(
        _ a: Lens<A, B1, B3>,
        _ b: Lens<A, B2, B4>
    ) -> Lens<A, (B1, B2), (B3, B4)> where B == (B1, B2), C == (B3, B4) { return
        Lens<A, (B1, B2), (B3, B4)>(
            constant: (
                a.constant,
                b.constant
            ),
            get: { constant, state in (
                a.get(constant.0, state),
                b.get(constant.1, state)
            ) },
            set: { parts, whole in
                a.set(parts.0, whole) +
                b.set(parts.1, whole)
            }
        )
    }

    static func zip<B1, B2, B3, B4, B5, B6>(
        _ a: Lens<A, B1, B3>,
        _ b: Lens<A, B2, B4>,
        _ c: Lens<A, B5, B6>
    ) -> Lens<A, (B1, B2, B5), (B3, B4, B6)> where B == (B1, B2, B5), C == (B3, B4, B6) { return
        Lens<A, (B1, B2, B5), (B3, B4, B6)>(
            constant: (
                a.constant,
                b.constant,
                c.constant
            ),
            get: { constant, state in (
                a.get(constant.0, state),
                b.get(constant.1, state),
                c.get(constant.2, state)
            ) },
            set: { parts, whole in
                a.set(parts.0, whole) +
                b.set(parts.1, whole) +
                c.set(parts.2, whole)
            }
        )
    }

    static func zip<B1, B2, B3, B4, B5, B6, B7, B8>(
        _ a: Lens<A, B1, B3>,
        _ b: Lens<A, B2, B4>,
        _ c: Lens<A, B5, B6>,
        _ d: Lens<A, B7, B8>
        ) -> Lens<A, (B1, B2, B5, B7), (B3, B4, B6, B8)> where B == (B1, B2, B5, B7), C == (B3, B4, B6, B8) { return
        Lens<A, (B1, B2, B5, B7), (B3, B4, B6, B8)>(
            constant: (
                a.constant,
                b.constant,
                c.constant,
                d.constant
            ),
            get: { constant, state in (
                a.get(constant.0, state),
                b.get(constant.1, state),
                c.get(constant.2, state),
                d.get(constant.3, state)
            ) },
            set: { parts, whole in
                a.set(parts.0, whole) +
                b.set(parts.1, whole) +
                c.set(parts.2, whole) +
                d.set(parts.3, whole)
            }
        )
    }

    static func zip<B1, B2, B3, B4, B5, B6, B7, B8, B9, B10>(
        _ a: Lens<A, B1, B3>,
        _ b: Lens<A, B2, B4>,
        _ c: Lens<A, B5, B6>,
        _ d: Lens<A, B7, B8>,
        _ e: Lens<A, B9, B10>
    ) -> Lens<A, (B1, B2, B5, B7, B9), (B3, B4, B6, B8, B10)> where B == (B1, B2, B5, B7, B9), C == (B3, B4, B6, B8, B10) { return
        Lens<A, (B1, B2, B5, B7, B9), (B3, B4, B6, B8, B10)>(
            constant: (
                a.constant,
                b.constant,
                c.constant,
                d.constant,
                e.constant
            ),
            get: { constant, state in (
                a.get(constant.0, state),
                b.get(constant.1, state),
                c.get(constant.2, state),
                d.get(constant.3, state),
                e.get(constant.4, state)
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

    static func map<D>(_ lens: Lens<A, B, C>, _ f: @escaping (A, B) -> D) -> Lens<A, D, C> { return
        Lens<A, D, C>(
            constant: lens.constant,
            get: { c, s in f(s, lens.get(c, s)) },
            set: { part, whole in
                lens.set(lens.get(lens.constant, whole), whole)
            }
        )
        // add test for multi map
    }

    func map<D>(_ f: @escaping (A, B) -> D) -> Lens<A, D, C> { return
        Lens.map(self, f)
    }

    func prefixed(with prefix: A) -> Lens<A, B, C> { return
        Lens(
            constant: constant,
            get: get,
            set: { b, a in [prefix] + self.set(b, a) }
        )
    }
}

protocol Lensable {}
extension NSObject: Lensable {}

extension Lensable where Self: NSObject {
    func lens<A, B>(get: @escaping (Self, A) -> B, set: @escaping (B, A) -> [A]) -> Lens<A, B, Self> { return
        Lens<A, B, Self>(
            constant: self,
            get: get,
            set: set
        )
    }
    func lens<A, B>(get: @escaping (Self, A) -> B, set: @escaping (B, A) -> A) -> Lens<A, B, Self> { return
        Lens<A, B, Self>(
            constant: self,
            get: get,
            set: set
        )
    }
    func lens<A, B>(get: @escaping (Self, A) -> B) -> Lens<A, B, Self> { return
        Lens<A, B, Self>(
            constant: self,
            get: get
        )
    }
}
