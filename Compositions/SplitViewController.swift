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

private func testSplitView() {
    let a: [UILabel] = ["hello", "goodbye", "hello"].map { x in
        x
            + UIColor.Text.foreground(.red)
            + UIScreen.main.bounds.size
    }
    let b = a.enumerated()
        .map { $0.element + .screenTitle(String($0.offset)) }
        / ScreenDivision.some
    
    let c: [UILabel] = ["hello", "goodbye", "hello"].map { x in
        x
            + UIColor.Text.foreground(.red)
            + UIScreen.main.bounds.size
    }
    let d = c.enumerated()
        .map { $0.element + .screenTitle(String($0.offset)) }
        / ScreenDivision.some
    
    _ = b + d + SplitView.some
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
