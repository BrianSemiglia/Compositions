//
//  String.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/16/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit

extension UIColor {
    enum Text {
        case foreground(UIColor)
        case background(UIColor)
    }
}

func + (left: String, right: UIColor.Text) -> NSAttributedString {
    switch right {
    case let .foreground(x):
        return NSAttributedString(
            string: left,
            attributes: [.foregroundColor: x]
        )

    case let .background(x):
        return NSAttributedString(
            string: left,
            attributes: [.backgroundColor: x]
        )
    }
}

func + (left: NSAttributedString, right: UIColor.Text) -> NSAttributedString {
    switch right {
    case let .foreground(x):
        return NSAttributedString(
            string: left.string,
            attributes: [.foregroundColor: x]
        )

    case let .background(x):
        return NSAttributedString(
            string: left.string,
            attributes: [.backgroundColor: x]
        )
    }
}
