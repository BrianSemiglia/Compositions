//
//  CompositionsTests.swift
//  CompositionsTests
//
//  Created by Brian Semiglia on 2/18/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import XCTest
import RxSwift
import RxBlocking

@testable import Compositions

class CompositionsTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        let x = Observable.just(0).share()
        let y = Observable.just(1).share()
        let z = x === y
        Observable.merge(
            Observable.amb([y, y, x]),
            y
        ).subscribe(onNext: {
            print($0)
        })
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testAsyncNode() {
        let a = AsyncNode(
            initial: 1,
            values: Observable.just(
                (1, Observable<Void>.never())
            )
        )
        XCTAssertEqual(a.initial, 1)
        XCTAssertEqual(try a.values.map { $0.0 }.toBlocking().toArray(), [1, 1])
    }

    func testMap() throws {
        let a = AsyncNode(
            initial: 1,
            values: Observable.just(
                (1, Observable<Void>.never())
            )
        )
        let b = a.map { $0 + 1 }
        XCTAssertEqual(b.initial, 2)
        XCTAssertEqual(try b.values.map { $0.0 }.toBlocking().toArray(), [2, 2])
    }

    func testFlatMap() throws {
        let a = AsyncNode(
            initial: 1,
            values: Observable.just(
                (1, Observable<Void>.never())
            )
        )
        let b = a.flatMap {
            AsyncNode(
                initial: $0 + 1,
                values: Observable.just(
                    (1, Observable<Void>.never())
                )
            )
        }
        XCTAssertEqual(b.initial, 2)
        XCTAssertEqual(try b.values.map { $0.0 }.toBlocking().toArray(), [2, 2, 1])
    }

}
