//
//  LensTests.swift
//  CompositionsTests
//
//  Created by Brian Semiglia on 8/2/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import XCTest
import RxSwift
import RxBlocking
import RxTest
import RxExpect
import SnapshotTesting
import RxCocoa

@testable import Compositions

class LensTests: XCTestCase {
    
    func testViewIdentity() throws {
        let view = UIView()
        let x = Lens(
            receiver: view,
            initial: 1,
            incoming: .empty()
        )
        .subscribed()

        XCTAssertEqual(x.receiver, view)
    }

    func testMapLeft() throws {
        let x = Lens(
            receiver: UILabel(),
            initial: 1,
            incoming: .empty()
        )
        .mapLeft { s, v -> UILabel in
            v.text = String(s)
            v.backgroundColor = .red
            v.sizeToFit()
            return v
        }
        .subscribed()

        assertSnapshot(
            matching: x.receiver,
            as: .image
        )
    }

    func testMapLeftMultipleStates() throws {
        let x = Lens(
            receiver: UILabel(),
            initial: 1,
            incoming: .just(2)
        )
        .mapLeft { s, v -> UILabel in
            v.text = String(s)
            v.backgroundColor = .red
            v.sizeToFit()
            return v
        }
        .subscribed()

        assertSnapshot(
            matching: x.receiver,
            as: .image
        )
    }

    func testMapLeftAppending() throws {
        let x = Lens(
            receiver: UILabel(),
            initial: 1,
            incoming: .empty()
        )
        .mapLeft(UIView()) { s, v1, v2 -> UIView in
            v1.text = String(s)
            v1.sizeToFit()
            v2.frame = CGRect(
                origin: .zero,
                size: CGSize(
                    width: v1.bounds.size.width + 10,
                    height: v1.bounds.size.height + 10
                )
            )
            v1.backgroundColor = .red
            v2.backgroundColor = .blue
            v2.addSubview(v1)
            return v2
        }
        .subscribed()

        assertSnapshot(
            matching: x.receiver,
            as: .image
        )
    }

    func testMapLeftMultipleStatesAppending() throws {
        let x = Lens(
            receiver: UILabel(),
            initial: 1,
            incoming: .from([2, 3])
        )
        .mapLeft(UIView()) { s, v1, v2 -> UIView in
            v1.text = String(s)
            v1.sizeToFit()
            v2.frame = CGRect(
                origin: .zero,
                size: CGSize(
                    width: v1.bounds.size.width + 10,
                    height: v1.bounds.size.height + 10
                )
            )
            v1.backgroundColor = .red
            v2.backgroundColor = .blue
            v2.addSubview(v1)
            return v2
        }
        .subscribed()

        assertSnapshot(
            matching: x.receiver,
            as: .image
        )
    }
    
    func testStateOutgoingNever() throws {
        let x = Lens(
            receiver: UIView(),
            initial: 1,
            incoming: .empty()
        )
        .subscribed()

        XCTAssertEqual(
            try x.outgoing.take(0).toBlocking().toArray(),
            []
        )
    }

    func testMapRightMultipleMap() throws {
        let x = Lens(
            receiver: UIView(),
            initial: 1,
            incoming: .empty()
        )
        .mapRight { s, v in .from([3]) }
        .mapRight { s, v in .from([4]) }
        .subscribed()

        XCTAssertEqual(
            try x.outgoing.take(2).toBlocking().toArray(),
            [3, 4]
        )
    }

    func testMapRightMultipleStates() throws {
        let x = Lens(
            receiver: UITextField(),
            initial: "1",
            incoming: Observable.from(["2", "3"])
        )
        .mapLeft { s, v in v.text = String(s); return v }
        .subscribed()
                
        XCTAssertEqual(
            x.receiver.text,
            "3"
        )
    }

    func testRecursiveUnique() throws {
        let x = CycledLens(
            lens: { source in
                Lens(
                    receiver: UILabel(),
                    initial: 1,
                    incoming: source
                )
                .mapLeft { s, v -> UILabel in
                    v.text = String(s)
                    return v
                }
                .mapRight { s, v in .just(1) }
                .subscribed()
            }
        )
        
        XCTAssertEqual(
            try x
                .receiver
                .rx
                .observe(String.self, "text")
                .take(1)
                .toBlocking()
                .toArray(),
            ["1"]
        )
    }

    func testRecursive() throws {
        let x = CycledLens(
            lens: { source in
                Lens(
                    receiver: UILabel(),
                    initial: 1,
                    incoming: source
                )
                .mapLeft { s, v -> UILabel in
                    v.text = String(s)
                    return v
                }
                .mapRight { s, v in .just(4) }
                .subscribed()
            }
        )

        XCTAssertEqual(
            try x
                .receiver
                .rx
                .observe(String.self, "text")
                .take(2)
                .toBlocking()
                .toArray(),
            ["1", "4"]
        )
    }
    
    func testRecursiveMultipleMapRight() throws {
        let x = CycledLens(
            lens: { source in
                Lens(
                    receiver: UILabel(),
                    initial: "1",
                    incoming: source
                )
                .mapLeft { s, v -> UILabel in
                    v.text = s
                    return v
                }
                .mapRight { s, v in
                    s.flatMap {
                        $0.count > 2
                            ? Observable.empty()
                            : Observable.just($0 + "2")
                    }
                }
                .mapRight { s, v in
                    s.flatMap {
                        $0.count > 2
                            ? Observable.empty()
                            : Observable.just($0 + "3")
                    }
                }
                .subscribed()
            }
        )
        
        XCTAssertEqual(
            try x
                .receiver
                .rx
                .observe(String.self, "text")
                .take(7)
                .toBlocking()
                .toArray(),
            ["1", "12", "13", "122", "123", "132", "133"]
        )
    }
    
    func testSubscribingOn() {
        let x = Lens(
            receiver: UILabel(),
            initial: 1,
            incoming: .just(3)
        )
        .mapLeft { s, v -> UILabel in v.text = String(s); return v; }
        .subscribingOn { s, v in
            v.rx
             .willMoveToSuperview
             .flatMap { $0 ? Observable.just(()) : Observable.never() }
        }
        x.receiver.willMove(toSuperview: UIView())
        
        XCTAssertEqual(
            x.receiver.text,
            "3"
        )
    }
    
    func testSubscribed() {
        let x = Lens(
            receiver: UILabel(),
            initial: 1,
            incoming: .just(3)
        )
        .mapLeft { s, v -> UILabel in v.text = String(s); return v; }
        .subscribed()
        
        XCTAssertEqual(
            x.receiver.text,
            "3"
        )
    }
    
    func testWithoutSubscribingOn() {
        let x = Lens(
            receiver: UILabel(),
            initial: 1,
            incoming: .just(3)
        )
        .mapLeft { s, v -> UILabel in v.text = String(s); return v; }
        
        XCTAssertEqual(
            x.receiver.text,
            nil
        )
    }
    
    func testSuperview() {
        let view = UIView()
        let test = RxExpect()
        test.scheduler.scheduleAt(100) { view.willMove(toSuperview: UIView()) }
        test.assert(view.rx.willMoveToSuperview) { events in
            XCTAssertEqual(
                events.filter(.next).elements,
                [true]
            )
        }
    }
}
