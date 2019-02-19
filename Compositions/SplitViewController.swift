//
//  SplitViewController.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/17/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit

enum SplitView {
    case some
}

func + (left: UIViewController, right: UIViewController) -> (SplitView) -> UISplitViewController {
    return { _ in
        let x = UISplitViewController()
        x.viewControllers = [left, right]
        return x
    }
}

func + (left: (SplitView) -> UISplitViewController, right: SplitView) -> UISplitViewController {
    return left(right)
}
