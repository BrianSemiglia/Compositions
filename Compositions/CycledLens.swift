//
//  CycledLens.swift
//  Compositions
//
//  Created by Brian Semiglia on 8/4/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

final class CycledLens<State: Equatable, Receiver: AnyObject> {
    
    private let publish = PublishSubject<State>()
    private let cleanup = DisposeBag()
    private let lens: Lens<State, Receiver>
    
    init(lens: (Observable<State>) -> Lens<State, Receiver>) {
        self.lens = lens(publish.asObservable())
        self
            .lens
            .outgoing
            .observeOn(MainScheduler.asyncInstance)
            .bind(to: publish)
            .disposed(by: cleanup)
    }
    
    var receiver: Receiver {
        return lens.receiver
    }
    
    var outgoing: Observable<State> {
        return lens.outgoing
    }
}
