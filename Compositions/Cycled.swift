//
//  Cycled.swift
//  Compositions
//
//  Created by Brian Semiglia on 8/10/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct Cycled<Receiver, Value: Equatable, Constant> {
    let receiver: Receiver
    private let producer = PublishSubject<Value>()
    private let cleanup = DisposeBag()
    init(lens: Lens<Observable<Value>, Receiver, Constant>) {
        let shared = producer
//            .materialize()
//            .flatMap { x -> Observable<Value> in
//                switch x {
//                case .completed: return .never()
//                case .error: return .never()
//                case .next(let x): return .just(x)
//                }
//            }
            .distinctUntilChanged()
            .share()
            .debug()
        receiver = lens.get(lens.constant, shared)
        Observable
            .merge(
                lens
                    .set(receiver, shared)
                    .reduce([]) { $0 + [$1] }
            )
            .observeOn(MainScheduler.asyncInstance)
            .bind(to: producer)
            .disposed(by: cleanup)
    }
}
