//
//  ImageView.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/16/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit
import RxSwift

//func +(left: UIImageView, right: CGSize) -> UIImageView {
//    left.frame.size = right
//    left.contentMode = .scaleAspectFill
//    left.heightAnchor.constraint(equalToConstant: right.height).isActive = true
//    left.widthAnchor.constraint(equalToConstant: right.width).isActive = true
//    left.clipsToBounds = true
//    left.isUserInteractionEnabled = true
//    return left
//}
//
//func +(left: UIImage, right: CGSize) -> UIImageView {
//    let x = UIImageView(image: left)
//    x.frame.size = right
//    x.contentMode = .scaleAspectFill
//    x.heightAnchor.constraint(equalToConstant: right.height).isActive = true
//    x.widthAnchor.constraint(equalToConstant: right.width).isActive = true
//    x.clipsToBounds = true
//    x.isUserInteractionEnabled = true
//    return x
//}
//
//func + <T>(left: (Observable<T>) -> AsyncNode<UIImageView, T>, right: Observable<T>) -> AsyncNode<UIImageView, T> {
//    return left(right)
//}

extension UIImageView {
    private static var cache = [UIImageView]()
    static var cached: UIImageView {
        if let cached = cache.first(where: { $0.superview == nil }) {
            cached.image = nil
            return cached
        } else {
            let new = UIImageView()
            cache += [new]
            return new
        }
    }
}

func + (left: UIImageView, right: CGSize) -> UIImageView {
    left.bounds = CGRect(origin: .zero, size: right)
    left.widthAnchor.constraint(equalToConstant: right.width)
    left.heightAnchor.constraint(equalToConstant: right.height)
    return left
}

extension UIImageView {
    struct Model {
        let image: UIImage?
        let size: CGSize
    }
}

extension UIImage {
    func imageWith(size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(
                in: .init(
                    origin: .zero,
                    size: size
                )
            )
        }
    }
}

func + <T>(left: Observable<UIImage>, right: CGSize) -> (Observable<T>) -> AsyncNode<UIView, T> {
    return { o in
        let x = UIImageView() //.cached
        x.contentMode = .scaleAspectFill
        x.clipsToBounds = true
        return AsyncNode<UIView, T>(
            initial: x + right, //UIImageView.cached + right,
            values: left
                .map { $0.imageWith(size: right) }
                .observeOn(MainScheduler.instance)
                .map { 
//                    let x = UIImageView.cached + right
                    x.contentMode = .scaleAspectFill
                    x.clipsToBounds = true
                    x.image = $0.imageWith(size: right)
                    return (x, x.rx.tapGesture().when(.recognized).flatMap { _ in o })
                }
            ,
            callbacks: .never()
        )
    }
}

func + <T>(left: (Observable<T>) -> AsyncNode<UIView, T>, right: Observable<T>) -> AsyncNode<UIView, T> {
    return left(right)
}
