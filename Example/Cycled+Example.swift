//
//  Cycled+Example.swift
//  Compositions
//
//  Created by Brian Semiglia on 8/10/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension UILabel {
    static func example() -> Cycled<(UIView, Void), String> {
        return Cycled { stream in
            let viewer = stream.lens(
                get: { s -> UILabel in
                    let x = UILabel()
                    x.backgroundColor = .red
                    x.frame = .init(
                        origin: CGPoint(x: 40, y: 40),
                        size: CGSize(width: 0, height: 0)
                    )
                    return x.rendering(s) { l, v in l.text = v; l.sizeToFit() }
                },
                set: { l, s in
                    Observable<Int>
                        .interval(.seconds(1), scheduler: MainScheduler())
                        .map(String.init)
                        .scan("") { x, y in x + y }
                }
            )
            .map { s, l -> UIView in
                let x = UIView()
                x.backgroundColor = .green
                x.addSubview(l)
                return x
            }
            .prefixed(with: .just("Hello World"))

            let animator = Observable<String>.never().lens(
                get: { a in },
                set: { b, a in
                    a.sample(
                        Observable<Int>.interval(
                            .milliseconds(1000 / 60),
                            scheduler: MainScheduler.instance
                        )
                    )
                    .flatMap { $0.count > 0 ? Observable.just($0) : Observable.never() }
                    .map { String($0.dropLast()) }
                }
            )

            return viewer.zip(animator)
        }
    }
}
