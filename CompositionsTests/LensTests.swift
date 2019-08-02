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
@testable import Compositions

class LensTests: XCTestCase {
    
    func testView() throws {
        let view = UIView()
        let x = Lens(
            view: view,
            initial: 1,
            states: Observable.just(2)
        )
        XCTAssertEqual(x.view, view)
    }
    
    func testStateOutgoingNever() throws {
        let x = Lens(
            view: UIView(),
            initial: 1,
            states: .empty()
        )
        XCTAssertEqual(try x.statesOutgoing.take(0).toBlocking().toArray(), [])
    }
    
    func testStateOutgoingJust() throws {
        let x = Lens(
            view: UIView(),
            initial: 1,
            states: .empty()
        )
        .mapRight { state, view in Observable.just(2) }
        XCTAssertEqual(try x.statesOutgoing.first().toBlocking().toArray(), [2])
    }
    
    func testStateOutgoingMapRightMultipleMap() throws {
        let x = Lens(
            view: UIView(),
            initial: 1,
            states: .empty()
        )
        .mapRight { s, v in Observable.from([3]) } //.concat(Observable.empty()) }
        .mapRight { s, v in Observable.from([4]) }
        
        XCTAssertEqual(
            try x.statesOutgoing.take(2).toBlocking().toArray().sorted(),
            [3, 4]
        )
    }
    
    func testStateOutgoingMapRightMultipleStates() throws {
        let x = Lens(
            view: UIView(),
            initial: 1,
            states: .from([2, 3])
        )
        .mapRight { s, v in .just(3) }
        .mapRight { s, v in .just(4) }
        .mapRight { s, v in .just(5) }
        .mapRight { s, v in .just(6) }
        
        XCTAssertEqual(
            try x.statesOutgoing.debug().take(23).toBlocking().toArray().sorted(),
            [3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6]
        )
    }
}
