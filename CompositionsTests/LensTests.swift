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

    func testLenzMapLeft() throws {
        let x = UILabel().lens(
            get: { l, a in
                l.rendering(a) { v, s in
                    v.text = String(s)
                    v.backgroundColor = .red
                    v.sizeToFit()
                }
            },
            set: { v, s in Observable<Int>.never() }
        )
        assertSnapshot(
            matching: x.get(x.constant, .just(1)),
            as: .image
        )
    }

    func testLenzMapLeftMultipleStates() throws {
        let x = UILabel().lens(
            get: { l, a in
                l.rendering(a) { v, s in
                    v.text = String(s)
                    v.backgroundColor = .red
                    v.sizeToFit()
                }
            },
            set: { v, s in Observable<Int>.never() }
        )
        assertSnapshot(
            matching: x.get(x.constant, .from([1, 2])),
            as: .image
        )
    }

    func testMapLeftAppending() throws {
        let x = UILabel().lens(
            get: { l, a -> UILabel in
                l.rendering(a) { v, s -> Void in
                    v.text = String(s)
                    v.backgroundColor = .red
                    v.sizeToFit()
                }
            },
            set: { v, s in Observable<Int>.never() }
        )
        .map { s, v1 -> UIView in
            let v2 = UIView()
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

        assertSnapshot(
            matching: x.get(x.constant, .just(1)),
            as: .image
        )
    }

    func testMapLeftMultipleStatesAppending() throws {
        let x = UILabel().lens(
            get: { l, s -> UILabel in
                l.rendering(s) { v, s -> Void in
                    v.text = String(s)
                    v.backgroundColor = .red
                    v.sizeToFit()
                }
            },
            set: { v, s in Observable<Int>.never() }
        )
        .map { s, v1 -> UIView in
            let v2 = UIView()
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
        .prefixed(with: .just(2))

        assertSnapshot(
            matching: x.get(x.constant, .just(3)),
            as: .image
        )
    }

    func testMapRightMultipleMap() throws {
        let x = UIView().lens(
            get: { v, s in v },
            set: { v, s in Observable.from([3, 4]) }
        )
        .prefixed(with: .just(1))

        XCTAssertEqual(
            try Observable.merge(
                x.set(
                    UIView(),
                    Observable.empty()
                )
            )
            .take(3)
            .toBlocking()
            .toArray(),
            [1, 3, 4]
        )
    }

    func testMapRightMultipleStates() throws {
        let x = UITextField().lens(
            get: { v, s in v.rendering(s) { v, s in v.text = String(s) } },
            set: { v, s in Observable<Int>.never() }
        )

        XCTAssertEqual(
            x.get(x.constant, .from([2, 3])).text,
            "3"
        )
    }

    func testRecursiveUnique() throws {
        let x = Cycled(
            lens: UILabel().lens(
                get: { v, s in v.rendering(s) { v, s in v.text = String(s) } },
                set: { v, s in Observable.just(1) }
            )
            .prefixed(with: .just(1))
        )

        XCTAssertEqual(
            try x
                .receiver
                .rx
                .observe(String.self, "text")
                .take(2)
                .toBlocking(timeout: 0.1)
                .toArray(),
            [nil, "1"]
        )

        XCTAssertThrowsError(
            try x
                .receiver
                .rx
                .observe(String.self, "text")
                .take(3)
                .toBlocking(timeout: 0.1)
                .toArray()
        )
    }

    func testRecursive() throws {
        let x = Cycled(
            lens: UILabel().lens(
                get: { l, s in l.rendering(s) { l, v in l.text = v } },
                set: { l, s in [Observable.just("4")] }
            )
            .prefixed(with: .just("1"))
        )

        XCTAssertEqual(
            try x
                .receiver
                .rx
                .observe(String.self, "text")
                .take(3)
                .toBlocking(timeout: 1)
                .toArray(),
            [nil, "1", "4"]
        )
    }


    func testCycledRecursive() throws {
        let x = Cycled(
            lens: UILabel().lens(
                get: { l, s in l.rendering(s) { l, v in l.text = v } },
                set: { l, s in Observable.from(["4", "5"]) }
            )
        )

        XCTAssertEqual(
            try x
                .receiver
                .rx
                .observe(String.self, "text")
                .debug()
                .take(3)
                .toBlocking(timeout: 1)
                .toArray(),
            [nil, "4", "5"]
        )
    }

    func testRecursiveMultipleMapRight() throws {
        let x = Cycled(
            lens: Lens<Observable<String>, UILabel, UILabel>(
                constant: UILabel(),
                get: { v, s in v.rendering(s) { l, v in l.text = v } },
                set: { v, s -> [Observable<String>] in [
                    s.flatMap {
                        $0.count > 2
                            ? Observable.empty()
                            : Observable.just($0 + "2")
                    },
                    s.flatMap {
                        $0.count > 2
                            ? Observable.empty()
                            : Observable.just($0 + "3")
                    }
                ]}
            )
            .prefixed(with: .just("1"))
        )

        XCTAssertEqual(
            try x
                .receiver
                .rx
                .observe(String.self, "text")
                .take(8)
                .toBlocking()
                .toArray(),
            [nil, "1", "12", "13", "122", "123", "132", "133"]
        )
    }

    func testSubscribingOn() {
        let x = Cycled(
            lens: UILabel().lens(
                get: { l, s in l.rendering(s) { l, v in l.text = v } },
                set: { l, s in
                    l.rx
                        .willMoveToSuperview
                        .flatMap { $0 ? Observable.just("3") : .never() }
                }
            )
        )
        x.receiver.willMove(toSuperview: UIView())

        XCTAssertEqual(
            try x
                .receiver
                .rx
                .observe(String.self, "text")
                .take(2)
                .toBlocking()
                .toArray(),
            [nil, "3"]
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

    func testStartingWith() {
        let x = Cycled(
            lens: UILabel().lens(
                get: { l, s in l.rendering(s) { l, v in l.text = v } },
                set: { v, s in Observable<String>.never() }
            )
            .prefixed(with: .just("99"))
        )

        XCTAssertEqual(
            try x
                .receiver
                .rx
                .observe(String.self, "text")
                .take(2)
                .toBlocking()
                .toArray(),
            [nil, "99"]
        )
    }

    func testLenzZip() {
        let a = Lens<String, Int, Int>(
            constant: 0,
            get: { i, s in Int(s)! },
            set: { i, s in "\(i)" }
        )
        XCTAssertEqual(a.get(a.constant, "1"), 1)
        XCTAssertEqual(a.set(4, ""), ["4"])
        let b = Lens<String, Int, Int>(
            constant: 0,
            get: { i, s in Int(s)! * 2 },
            set: { i, s in "\(i * 2)" }
        )
        let c = Lens.zip(a, b)
        XCTAssertEqual(c.get(c.constant, "3").0, 3)
        XCTAssertEqual(c.get(c.constant, "3").1, 6)
        XCTAssertEqual(c.set((2, 5), ""), ["2", "10"])
    }
}
