//
//  ImageView.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/16/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit

func +(left: UIImage, right: CGSize) -> UIImageView {
    let x = UIImageView(image: left)
    x.frame.size = right
    return x
}
