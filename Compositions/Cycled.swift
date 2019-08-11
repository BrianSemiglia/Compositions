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

struct Cycled<Receiver, Value> {
    let receiver: Receiver
    private let producer = PublishSubject<Value>()
    private let cleanup = DisposeBag()
    init(lens: Lens<Observable<Value>, Receiver>) {
        let shared = producer.asObservable().share()
        receiver = lens.get(shared)
        Observable
            .merge(
                lens
                    .set(receiver, shared)
                    .reduce([]) { $0 + [$1] }
            )
            .debug()
            .observeOn(MainScheduler.asyncInstance)
            .concat(Observable.never())
            .bind(to: producer)
            .disposed(by: cleanup)
    }
}
