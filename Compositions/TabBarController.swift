//
//  TabBarController.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/17/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit

enum TabDivision {
    case some
}

private func testTabBarController() {
    let p: [UILabel] = ["hello", "goodbye", "hello"].map { x in
        x
            + UIColor.Text.foreground(.red)
            + UIScreen.main.bounds.size
    }
    _ = p.enumerated()
        .map { $0.element + .screenTitle(String($0.offset)) }
        / TabDivision.some
}

func / (left: [UIViewController], right: TabDivision) -> UITabBarController {
    let x = UITabBarController()
    x.viewControllers = left
    return x
}
