//
//  Lens.swift
//  Compositions
//
//  Created by Brian Semiglia on 8/2/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class Lens<State: Equatable, View> {
    
    var view: View
    private var latest: State
    private let statesIncoming: Observable<State>
    private let outgoing: [Observable<State>]
    let left: (State, View) -> View
    private let cleanup = DisposeBag()
    
    init(
        view: View,
        initial: State,
        states: Observable<State>
    ) {
        self.view = view
        self.latest = initial
        self.statesIncoming = Observable.merge(Observable.just(initial), states).share()
        self.outgoing = []
        self.left = { _, x in x }
    }
    
    private init(
        view: View,
        initial: State,
        states: Observable<State>,
        outgoing: [Observable<State>] = [],
        left: @escaping ((State, View) -> View) = { _, x in x }
    ) {
        self.view = left(initial, view)
        self.latest = initial
        self.statesIncoming = Observable.merge(Observable.just(initial), states).share()
        self.outgoing = outgoing
        self.left = left
        self.statesIncoming
            .subscribe(onNext: { [weak self] in
                self?.view = left($0, view)
            })
            .disposed(by: cleanup)
    }
    
    var statesOutgoing: Observable<State> {
        return .merge(outgoing)
    }
    
    func mapLeft<NewView>(_ v: NewView, _ f: @escaping (State, View, NewView) -> NewView) -> Lens<State, NewView> {
        let view = self.view
        let left = self.left
        return Lens<State, NewView>(
            view: v,
            initial: latest,
            states: statesIncoming,
            outgoing: outgoing,
            left: { state, _ in f(state, left(state, view), v) }
        )
    }
    
    func mapRight(_ f: @escaping (State, View) -> Observable<State>) -> Lens<State, View> {
        let view = self.view
        return Lens<State, View>.init(
            view: view,
            initial: latest,
            states: statesIncoming,
            outgoing: outgoing + [statesIncoming.flatMap { f($0, view) }]
        )
    }
}
