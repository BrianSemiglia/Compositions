//
//  AttributedString.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/16/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit

extension UILabel {
    struct Model {
        let attributedString: NSAttributedString
        let size: CGSize.Preset
    }
}

extension CGSize {
    enum Preset {
        case manual(CGFloat, CGFloat)
        case intrinsic
    }
}

func + (left: NSAttributedString, right: CGSize) -> UILabel {
    let x = UILabel()
    x.frame = CGRect(origin: .zero, size: right)
    x.attributedText = left
    return x
}

func + (left: NSAttributedString, right: CGSize) -> UILabel.Model {
    return UILabel.Model(
        attributedString: left,
        size: .manual(right.width, right.height)
    )
}

func + (left: NSAttributedString, right: CGSize.Preset) -> UILabel {
    let x = UILabel()
    x.attributedText = left
    switch right {
    case let .manual(w, h):
        x.frame = CGRect(origin: .zero, size: CGSize(width: w, height: h))
    case .intrinsic:
        x.sizeToFit()
    }
    return x
}

func + (left: NSAttributedString, right: CGSize.Preset) -> UILabel.Model {
    return UILabel.Model(
        attributedString: left,
        size: right
    )
}
