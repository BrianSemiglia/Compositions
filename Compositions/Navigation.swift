//
//  Navigation.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/16/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit

class NavigationTest {

    func testNavigation() {
        let p = ["hello", "goodbye", "hello"].map { x in
            x
                + UIColor.Text.foreground(.red)
                + UIScreen.main.bounds.size
                + UIScreen.main.bounds.size
                + UIScreen.main.bounds.size
        }
        _ = p.map { $0 + .screenTitle("title") } / ScreenDivision.some
    }

    func testTabBarController() {
        let p: [UILabel] = ["hello", "goodbye", "hello"].map { x in
            x
                + UIColor.Text.foreground(.red)
                + UIScreen.main.bounds.size
        }
        _ = p.enumerated()
            .map { $0.element + .screenTitle(String($0.offset)) }
            / TabDivision.some
    }

    func testSplitView() {
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

}
