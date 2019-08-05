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

final class Lens<State: Equatable, Receiver> {
  
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
        self.incoming = Observable
            .merge(.just(initial), incoming)
            .distinctUntilChanged()
        self._outgoing = []
        self.left = { _, x in x }
    }
    
    private init( // tail
        receiver: Receiver,
        initial: State,
        incoming: Observable<State>,
        outgoing: [Observable<State>],
        left: @escaping ((State, Receiver) -> Receiver)
    ) {
        self.receiver = receiver
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

    func mapLeft(_ f: @escaping (State, Receiver) -> Receiver) -> Lens<State, Receiver> {
        let receiver = self.receiver
        let left = self.left
        return Lens<State, Receiver>(
            receiver: receiver,
            initial: initial,
            incoming: incoming,
            outgoing: _outgoing,
            left: { s, _ in f(s, left(s, receiver)) }
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
    
    func mapRight(_ f: @escaping (Observable<State>, Receiver) -> Observable<State>) -> Lens<State, Receiver> {
        return Lens<State, Receiver>(
            receiver: receiver,
            initial: initial,
            incoming: incoming,
            outgoing: _outgoing + [f(incoming, receiver)],
            left: left
        )
    }
}
