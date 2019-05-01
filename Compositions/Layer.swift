//
//  Layer.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/19/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit

func + (left: UIColor, right: CGSize) -> CALayer {
    let x = CALayer()
    x.frame = .init(origin: .zero, size: right)
    x.backgroundColor = left.cgColor
    return x
}

func + (left: UIColor, right: CGSize) -> UIView {
    let x = UIView()
    x.frame = .init(origin: .zero, size: right)
    x.layer.addSublayer(left + right)
    return x
}

private func tests() {
    let _: UIViewController = .red + UIScreen.main.bounds.size
    let _: UIView = .red + UIScreen.main.bounds.size
    let _: CALayer = .red + UIScreen.main.bounds.size
}

func + (left: UIColor, right: CGSize) -> UIViewController {
    let x = UIViewController()
    x.view = left + right
    return x
}
