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
        let x = Lens<Observable<Int>, UILabel>(
            get: { a in
                UILabel().rendering(a) { v, s in
                    v.text = String(s)
                    v.backgroundColor = .red
                    v.sizeToFit()
                }
            }
        )
        assertSnapshot(
            matching: x.get(.just(1)),
            as: .image
        )
    }

    func testLenzMapLeftMultipleStates() throws {
        let x = Lens<Observable<Int>, UILabel>(
            get: { a in
                UILabel().rendering(a) { v, s in
                    v.text = String(s)
                    v.backgroundColor = .red
                    v.sizeToFit()
                }
            }
        )
        assertSnapshot(
            matching: x.get(.from([1, 2])),
            as: .image
        )
    }

    func testMapLeftAppending() throws {
        let x = Lens<Observable<Int>, UILabel>(
            get: { a -> UILabel in
                UILabel().rendering(a) { v, s -> Void in
                    v.text = String(s)
                    v.backgroundColor = .red
                    v.sizeToFit()
                }
            }
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
            matching: x.get(.just(1)),
            as: .image
        )
    }

    func testMapLeftMultipleStatesAppending() throws {
        let x = Lens<Observable<Int>, UILabel>(
            get: { s -> UILabel in
                UILabel().rendering(s) { v, s -> Void in
                    v.text = String(s)
                    v.backgroundColor = .red
                    v.sizeToFit()
                }
            }
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
            matching: x.get(.just(3)),
            as: .image
        )
    }

    func testMapRightMultipleMap() throws {
        let x = Lens<Observable<Int>, UIView>(
            get: { s in UIView() },
            set: { v, s in [.from([3, 4])] }
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
        let x = Lens<Observable<Int>, UITextField>(
            get: { s in UITextField().rendering(s) { v, s in v.text = String(s) } },
            set: { v, s in [] }
        )

        XCTAssertEqual(
            x.get(.from([2, 3])).text,
            "3"
        )
    }

    func testRecursiveUnique() throws {
        let x = Cycled(
            lens: Lens(
                get: { s in UILabel().rendering(s) { v, s in v.text = String(s) } },
                set: { s, v in [Observable.just(1)] }
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
            lens: Lens<Observable<String>, UILabel>(
                get: { s in UILabel().rendering(s) { l, v in l.text = v } },
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
            lens: Lens<Observable<String>, UILabel>(
                get: { s in UILabel().rendering(s) { l, v in l.text = v } },
                set: { l, s in [Observable.from(["4", "5"])] }
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
            lens: Lens<Observable<String>, UILabel>(
                get: { s in UILabel().rendering(s) { l, v in l.text = v } },
                set: { l, s in [
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
                ] }
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
            lens: Lens<Observable<String>, UILabel>(
                get: { s in UILabel().rendering(s) { l, v in l.text = v } },
                set: { l, s in [
                    l.rx
                        .willMoveToSuperview
                        .flatMap { $0 ? Observable.just("3") : .never() }
                ] }
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
            lens: Lens<Observable<String>, UILabel>(
                get: { s in UILabel().rendering(s) { l, v in l.text = v } },
                set: { l, s in [] }
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
        let a = Lens<String, Int>(get: { s in Int(s)! }, set: { i, s in ["\(i)"] })
        XCTAssertEqual(a.get("1"), 1)
        XCTAssertEqual(a.set(4, ""), ["4"])
        let b = Lens<String, Int>(get: { s in Int(s)! * 2 }, set: { i, s in ["\(i * 2)"] })
        let c = Lens.zip(a, b)
        XCTAssertEqual(c.get("3").0, 3)
        XCTAssertEqual(c.get("3").1, 6)
        XCTAssertEqual(c.set((2, 5), ""), ["2", "10"])
    }
}
