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

struct Cycled<Receiver, Value: Equatable> {
    
    let receiver: Receiver
    private let producer = PublishSubject<Value>()
    private let cleanup = DisposeBag()
    
    init(lens: (Observable<Value>) -> Lens<Observable<Value>, Receiver>) {
        let lens = lens(
            producer
                .distinctUntilChanged()
                .share()
                .debug()
        )
        receiver = lens.get
        Observable
            .merge(lens.set)
            .observeOn(MainScheduler.asyncInstance)
            .bind(to: producer)
            .disposed(by: cleanup)
    }
}
