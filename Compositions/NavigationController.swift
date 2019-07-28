//
//  NavigationController.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/16/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit
import RxSwift

extension Navigation {
    static func example() -> AsyncNode<Navigation<Events.Model>, Events.Model> {
        let x = (URL(string: "https://rzdoorman.herokuapp.com/api/v1/facilities/14")! / TopLevelThing.self)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map { $0
                .companies
                .flatMap { $0.departments }
                .flatMap { $0.employees }
            }
            .observeOn(MainScheduler.instance)
//            .map { $0.prefix(1) }
            .map { people in
                people.map { person -> AsyncNode<UIView, Events.Model> in
                    let x = (person.mugshot / UIImage.self)//.share(replay: 1, scope: .forever)
                    let y = CGSize(width: UIScreen.main.bounds.width, height: 300)
                    let z = Observable.just(Events.Model.didSelectPerson(person))
                    let n = (x + y + z)
                    return n.map { x -> UIView in
                        x + .vertical(10) + (
                            person.firstName
                            + UIColor.Text.foreground(UIColor.green)
                            + CGSize(width: UIScreen.main.bounds.width, height: 44.0)
                        )
                    }
                }
        }
        return x / ScreenDivision.some
    }
}

private func testNavigation() {
    let p = ["hello", "goodbye", "hello"].map { x in
        x
            + UIColor.Text.foreground(.red)
            + UIScreen.main.bounds.size
            + UIScreen.main.bounds.size
            + UIScreen.main.bounds.size
    }
    _ = p.map { $0 + .screenTitle("title") } / ScreenDivision.some
}

enum ScreenDivision {
    case some
}

enum ScreenWhole {
    case some
}

enum ScreenTitle {
    case screenTitle(String)
}

func / <T>(left: Observable<[AsyncNode<UIStackView, T>]>, right: ScreenDivision) -> AsyncNode<Navigation<T>, T> {
    let x = Navigation<T>(views: [])
    return AsyncNode(
        initial: x,
        values: left.map {
            x.views = $0.map { $0.map { $0 as UIView } }
            return (x, x.callbacks)
        }
    )
}

func / <T>(left: Observable<[AsyncNode<UIView, T>]>, right: ScreenDivision) -> AsyncNode<Navigation<T>, T> {
    let x = Navigation<T>(views: [])
    return AsyncNode(
        initial: x,
        values: left.map {
            x.views = $0
            return (x, x.callbacks)
        }
    )
}

func / <T>(left: [AsyncNode<UIView, T>], right: ScreenDivision) -> Navigation<T> {
    return Navigation(views: left)
}

func / (left: [UIViewController], right: ScreenDivision) -> UINavigationController {
    let x = UINavigationController(rootViewController: UIViewController())
    x.viewControllers = left
    return x
}

func + (left: UIView, right: ScreenWhole) -> UIViewController {
    let x = UIViewController()
    x.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    x.view.addSubview(left)
    return x
}

func + (left: UIView, right: ScreenTitle) -> UIViewController {
    switch right {
    case .screenTitle(let value):
        let x = UIViewController()
        x.title = value
        x.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        x.view.addSubview(left)
        return x
    }
}

func + (left: UIViewController, right: ScreenTitle) -> UIViewController {
    switch right {
    case .screenTitle(let value):
        left.title = value
        return left
    }
}

extension UINavigationController {
    struct Model {
        struct View {
            let title: String
            let content: UIViewController
        }
        let views: [View]
    }
}

final class Navigation<T>: UINavigationController {
    
    var views: [AsyncNode<UIView, T>] {
        didSet {
            viewControllers = views.map {
                let x = AsyncViewController(model: $0.values, index: 0)
                x.view.backgroundColor = .white
                return x
            }
            Observable
                .merge(views.map { $0.values.flatMap { $0.1 } })
                .bind(to: callbacks)
                .disposed(by: cleanup)
        }
    }
    let callbacks = PublishSubject<T>()
    private let cleanup = DisposeBag()
    
    init(views: [AsyncNode<UIView, T>]) {
        self.views = []
        super.init(rootViewController: UIViewController())
        self.views = views
        if views.count > 0 {
            viewControllers = views.map {
                let x = AsyncViewController(model: $0.values, index: 0)
                x.view.backgroundColor = .white
                return x
            }
        }
    }
    
    @available(*, unavailable) required init?(coder: NSCoder) {
        self.views = []
        super.init(coder: coder)
    }
    
    @available(*, unavailable) override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.views = []
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
}
