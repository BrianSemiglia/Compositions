//
//  Enum.swift
//  Compositions
//
//  Created by Brian Semiglia on 3/11/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import Foundation

private func enumFooTest() -> String { return
    EnumFoo.one
        / Switch.some
        + { return "one" }
        + { return "two" }
        + { return $0 }
}

enum EnumFoo {
    case one
    case two
    case three(String)
}

enum Switch {
    case some
}

func / <T>(left: EnumFoo, right: Switch) -> (@escaping () -> T) -> (@escaping () -> T) -> (@escaping (String) -> T) -> T {
    return { (one: @escaping () -> T) in
        return { (two: @escaping () -> T) in
            return { (three: @escaping (String) -> T) in
                switch left {
                case .one: return one()
                case .two: return two()
                case .three(let x): return three(x)
                }
            }
        }
    }
}

func + <T, U>(
    left: (@escaping () -> T) -> (@escaping () -> U) -> (@escaping (T) -> U) -> U,
    right: @escaping () -> T
) -> (@escaping () -> U) -> (@escaping (T) -> U) -> U {
    return left(right)
}

func + <T, U>(
    left: (@escaping () -> U) -> (@escaping (T) -> U) -> U,
    right: @escaping () -> U
) -> (@escaping (T) -> U) -> U {
    return left(right)
}

func + <T, U>(
    left: (@escaping (T) -> U) -> U,
    right: @escaping (T) -> U
) -> U {
    return left(right)
}
