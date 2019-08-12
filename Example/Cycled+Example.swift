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

extension UIView {
    static func animated() -> Cycled<(UIView, Void), String> { return
        Cycled { stream in
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

            let animator = stream.lens(
                get: { a in },
                set: { b, a in
                    a.sample(
                        Observable<Int>.interval(
                            .milliseconds(1000 / 60),
                            scheduler: MainScheduler.instance
                        )
                    )
                    .flatMap { $0.count > 0 ? Observable.just($0) : .never() }
                    .map { String($0.dropLast()) }
                }
            )

            return viewer.zip(animator)
        }
    }
    
    static func async() -> Cycled<(BlueToothAdapter, UIViewController), State> { return
        Cycled { source in
            let bluetooth = source.lens(
                get: { state in
                    BlueToothAdapter().rendering(state) { adapter, state in
                        if state.transmission == .sending {
                            _ = adapter.sending(state.text)
                        }
                    }
                },
                set: { adapter, state in
                    adapter
                        .bytes()
                        .withLatestFrom(state) { ($0, $1) }
                        .map { response, state in
                            var new = state
                            new.responses = state.responses + [response]
                            new.transmission = .idle
                            return new
                    }
                }
            )
            
            let view = Lens<Observable<State>, (UITextView, UITextView)>(
                value: source,
                get: { state in (
                    UITextView().rendering(state) { view, state in
                        view.frame = .init(
                            origin: .init(x: 30, y: 60),
                            size: .init(width: 300, height: 44)
                        )
                        view.text = state.text
                        view.backgroundColor = state.text.count % 2 == 0 ? .yellow : .red
                    },
                    UITextView().rendering(state) { view, state in
                        view.frame = .init(
                            origin: .init(x: 30, y: 130),
                            size: .init(width: 300, height: 600)
                        )
                        view.text = state.responses.reduce("") { $0 + "\n" + $1 }
                    }
                )},
                set: { views, state -> Observable<State> in
                    views
                        .0
                        .rx
                        .text
                        .map { $0! }
                        .withLatestFrom(state) { ($0, $1) }
                        .filter { $0 != $1.text }
                        .map { text, state in
                            var new = state
                            new.text = text
                            new.transmission = .sending
                            return new
                        }
                }
            )
            
            let viewController = view.map { state, views -> UIViewController in
                let x = UIViewController()
                x.view.backgroundColor = .blue
                x.view.addSubview(views.0)
                x.view.addSubview(views.1)
                return x
            }
            
            let composed = bluetooth
                .zip(viewController)
                .prefixed(
                    with: .just(
                        State(
                            text: "Hello World",
                            responses: [],
                            transmission: .idle
                        )
                    )
                )
            
            return composed
        }
    }
}

final class BlueToothAdapter: NSObject {
    
    private let output = PublishSubject<String>()
    
    func sending(_ input: String) -> BlueToothAdapter {
        output.on(.next(input + " response"))
        return self
    }
    
    func bytes() -> Observable<String> { return
        output
            .asObservable()
            .delay(
                .seconds(1),
                scheduler: MainScheduler()
            )
    }
}

struct State: Equatable {
    enum TransmissionState: Equatable {
        case idle
        case sending
        case receiving
    }
    var text: String
    var responses: [String]
    var transmission: TransmissionState
}
