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

class Lens<State: Equatable, Receiver> {
    
    var receiver: Receiver
    private let initial: State
    private let incoming: Observable<State>
    private let _outgoing: [Observable<State>]
    let left: (State, Receiver) -> Receiver
    private let cleanup = DisposeBag()
    
    init( // head
        receiver: Receiver,
        initial: State,
        incoming: Observable<State>
    ) {
        self.receiver = receiver
        self.initial = initial
        self.incoming = Observable.merge(.just(initial), incoming).distinctUntilChanged()
        self._outgoing = []
        self.left = { _, x in x }
    }
    
    private init( // tail
        receiver: Receiver,
        initial: State,
        incoming: Observable<State>,
        outgoing: [Observable<State>] = [],
        left: @escaping ((State, Receiver) -> Receiver) = { _, x in x }
    ) {
        self.receiver = left(initial, receiver)
        self.initial = initial
        self.incoming = incoming
        self._outgoing = outgoing
        self.left = left
    }
    
    func subscribingOn(_ trigger: (State, Receiver) -> Observable<Void>) -> Lens {
        let incoming = self.incoming
        trigger(initial, receiver)
            .flatMap { incoming }
            .subscribe(onNext: { [weak self] in
                if let `self` = self {
                    self.receiver = self.left(
                        $0,
                        self.receiver
                    )
                }
            })
            .disposed(by: cleanup)
        return self
    }
    
    func subscribed() -> Lens {
        // need to be able to get subsets as needed
        // table view only needs some of the data as views
        return subscribingOn { _, _ in .just(()) }
    }
    
    var outgoing: Observable<State> {
        return .merge(_outgoing)
    }

    func mapLeft<NewReceiver>(_ f: @escaping (State, Receiver) -> NewReceiver) -> Lens<State, NewReceiver> {
        let receiver = self.receiver
        let left = self.left
        return Lens<State, NewReceiver>(
            receiver: f(initial, receiver),
            initial: initial,
            incoming: incoming,
            outgoing: _outgoing,
            left: { state, _ in f(state, left(state, receiver)) }
        )
    }

    func mapLeft<NewReceiver>(_ v: NewReceiver, _ f: @escaping (State, Receiver, NewReceiver) -> NewReceiver) -> Lens<State, NewReceiver> {
        let receiver = self.receiver
        let left = self.left
        return Lens<State, NewReceiver>(
            receiver: v,
            initial: initial,
            incoming: incoming,
            outgoing: _outgoing,
            left: { state, _ in f(state, left(state, receiver), v) }
        )
    }
    
    func mapRight(_ f: @escaping (State, Receiver) -> Observable<State>) -> Lens<State, Receiver> {
        let receiver = self.receiver
        return Lens<State, Receiver>(
            receiver: receiver,
            initial: initial,
            incoming: incoming,
            outgoing: _outgoing + [incoming.flatMapLatest { f($0, receiver) }],
            left: left
        )
    }

    func reinjectingOutgoingState() -> Lens<State, Receiver> {
        return Lens(
            receiver: receiver,
            initial: initial,
            incoming: outgoing,
            left: left
        )
    }
}

public extension Reactive where Base: UIView {
    var willMoveToSuperview: ControlEvent<Bool> {
        return ControlEvent(
            events: methodInvoked(#selector(UIView.willMove(toSuperview:)))
                .map { $0.first }
                .map { $0 as? UIView? }
                .map { $0 != nil }
        )
    }
}
