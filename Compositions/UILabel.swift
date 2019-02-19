//
//  UILabel.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/16/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit

func + <T>(left: Node<UIStackView, T>, right: UIImageView) -> Node<UIView, T> {
    return Node(
        value: left.value + right,
        callback: left.callback
    )
}

func + <T>(left: Node<UIStackView, T>, right: UILabel) -> Node<UIStackView, T> {
    return Node(
        value: left.value + right,
        callback: left.callback
    )
}
