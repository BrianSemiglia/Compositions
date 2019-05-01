//
//  Collection.swift
//  Compositions
//
//  Created by Brian Semiglia on 3/12/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import Foundation

private func collectionTest() {
    let b = Array<Int>.self / (\Int.hashValue)
}

func / <T, U>(left: Array<T>.Type, right: KeyPath<T, U>) -> ((Array<T>) -> Array<U>) {
    return { left in
        left.map { $0[keyPath: right] }
    }
}

func / <T, U>(left: Array<T>.Type, right: @escaping (T) -> U) -> ((Array<T>) -> Array<U>) {
    return { (array: Array<T>) in
        array.map(right)
    }
}
