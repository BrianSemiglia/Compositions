//
//  NavigationController.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/16/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit

enum ScreenDivision {
    case some
}

enum ScreenWhole {
    case some
}

enum ScreenTitle {
    case screenTitle(String)
}

func / (left: [UIViewController], right: ScreenDivision) -> UINavigationController {
    let x = UINavigationController(rootViewController: UIViewController())
    x.viewControllers = left
    return x
}

func + (left: UIView, right: ScreenWhole) -> UIViewController {
    let x = UIViewController()
    x.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    x.view.addSubview(left)
    return x
}

protocol UIViewModelable {
    // exists to allow re-rendering of UINavigationController using same value (vs instance) pipeline
    func render() -> UIView
}

//func + (left: UIViewModelable, right: ScreenTitle) -> UIViewController {
    // viewController.model = Model(title: right, content: left)
//}

func + (left: UIView, right: ScreenTitle) -> UIViewController {
    switch right {
    case .screenTitle(let value):
        let x = UIViewController()
        x.title = value
        x.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        x.view.addSubview(left)
        return x
    }
}

func + (left: UIViewController, right: ScreenTitle) -> UIViewController {
    switch right {
    case .screenTitle(let value):
        left.title = value
        return left
    }
}

extension UINavigationController {
    struct Model {
        struct View {
            let title: String
            let content: UIViewController
        }
        let views: [View]
    }
}
