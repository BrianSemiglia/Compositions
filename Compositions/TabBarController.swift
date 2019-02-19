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

func / (left: [UIViewController], right: TabDivision) -> UITabBarController {
    let x = UITabBarController()
    x.viewControllers = left
    return x
}
