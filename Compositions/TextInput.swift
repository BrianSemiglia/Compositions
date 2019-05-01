//
//  TextInput.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/21/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

func testTextField() -> Node<UITextField, String?> { return
    String.self + CGSize(width: 200, height: 200)
}

func + (left: String.Type, right: CGSize) -> Node<UITextField, String?> {
//    return { o in
        let x = UITextField(
            frame: .init(
                origin: .zero,
                size: right
            )
        )
        return Node(
            value: x,
            callback: x.rx.text.flatMap { Observable.just($0) }
        )
//    }
}

func + (
    left: (Observable<String?>.Type) -> Node<UITextField, String?>,
    right: Observable<String?>.Type) -> Node<UITextField, String?> {
    return left(right)
}
