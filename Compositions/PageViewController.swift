//
//  PageViewController.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/17/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension PageViewController {
    static func example() -> AsyncNode<PageViewController<Events.Model>, Events.Model> {
        let x = (URL(string: "https://rzdoorman.herokuapp.com/api/v1/facilities/14")! / TopLevelThing.self)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map { $0
                .companies
                .flatMap { $0.departments }
                .flatMap { $0.employees }
            }
            .observeOn(MainScheduler.instance)
            .map { people in
                people.map { person -> AsyncNode<UIView, Events.Model> in
                    let x = (person.mugshot / UIImage.self)//.share(replay: 1, scope: .forever)
                    let y = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 44)
                    let z = Observable.just(Events.Model.didSelectPerson(person))
                    let n = (x + y + z)
                    return n
                }
        }
        return x / PageDivision.vertical
    }
}

enum PageDivision {
    case horizontal
    case vertical
}

func / <T>(
    left: Observable<[AsyncNode<UIView, T>]>,
    right: PageDivision
) -> AsyncNode<PageViewController<T>, T> {
    let x = PageViewController<T>(
        model: [],
        orientation: right.coerced()
    )
    return AsyncNode(
        initial: x,
        values: left.map {
            x.pages = $0;
            return (
                x,
                x.callbacks
            )
        },
        callbacks: .never()
    )
}

func / <T>(
    left: [AsyncNode<UIView, T>],
    right: PageDivision
) -> AsyncNode<PageViewController<T>, T> {
    let x = PageViewController<T>(
        model: [],
        orientation: right.coerced()
    )
    return AsyncNode(
        initial: x,
        values: Observable.just(left).map {
            x.pages = $0;
            return (
                x,
                x.callbacks
            )
        },
        callbacks: .never()
    )
}

extension PageDivision {
    func coerced() -> UIPageViewController.NavigationOrientation {
        switch self {
        case .horizontal: return .horizontal
        case .vertical: return .vertical
        }
    }
}

final class PageViewController<T>: UIPageViewController, UIPageViewControllerDataSource {

    let callbacks = PublishSubject<T>()
    private let cleanup = DisposeBag()
    var pages: [AsyncNode<UIView, T>] = [] { // nodes are retaining memory?
        didSet {
            render(model: pages)
        }
    }
    private var views: [AsyncViewController<T>]
    
    required init(model: [AsyncNode<UIView, T>], orientation: NavigationOrientation) {
        self.pages = model
        self.views = model.map {
            let x = AsyncViewController(model: $0.values)
            x.view.backgroundColor = .white
            return x
        }
//        Observable COMMENTING OUT FIXES CALLBACK ISSUE. BINDING TWICE SEEMS TO CAUSE ISSUE.
//            .merge(views.map { $0.callbacks })
//            .bind(to: callbacks)
//            .disposed(by: cleanup)
        super.init(
            transitionStyle: .scroll,
            navigationOrientation: orientation
        )
        dataSource = self
        if let first = views.first {
            setViewControllers(
                [first],
                direction: .forward,
                animated: false
            )
        }
    }
    func render(model: [AsyncNode<UIView, T>]) {
        views = model.map {
            let x = AsyncViewController(model: $0.values)
            x.view.backgroundColor = .white
            return x
        }
        Observable
            .merge(views.map { $0.callbacks })
            .bind(to: callbacks)
            .disposed(by: cleanup)
        setViewControllers(
            views.first.map { [$0] } ?? [],
            direction: .forward,
            animated: false
        )
    }
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        if let input = viewController as? AsyncViewController<T> {
            return views
                .firstIndex(of: input)
                .map { $0 - 1 }
                .flatMap {
                    $0 >= 0
                        ? views[$0]
                        : Optional<UIViewController>.none
                }
        } else {
            return nil
        }
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        if let input = viewController as? AsyncViewController<T> {
            return views
                .firstIndex(of: input)
                .map { $0 + 1 }
                .flatMap {
                    $0 >= 0 && $0 < views.count
                        ? views[$0]
                        : Optional<UIViewController>.none
                }
        } else {
            return nil
        }
    }
    @available(*, unavailable) required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class AsyncViewController<T>: UIViewController {
    
    let callbacks = PublishSubject<T>()
    let model: Observable<(UIView, Observable<T>)>
    private let cleanup = DisposeBag()
    private var _presentation: Disposable?
    private var _callback: Disposable?
    
    init(model: Observable<(UIView, Observable<T>)>) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let new = model.debug().subscribe(onNext: { [weak self] in
            if let `self` = self {
                self.view.subviews.forEach { $0.removeFromSuperview() }
                let new = $0.1.debug().bind(to: self.callbacks)
                self._callback = new
                self.cleanup.insert(new)
                $0.0.frame = self.view.bounds
                self.view.addSubview($0.0)
            }
        })
        _presentation = new
        cleanup.insert(new)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        _callback?.dispose()
        _presentation?.dispose()
        view.subviews.forEach { $0.removeFromSuperview() }
    }
    
    @available(*, unavailable) required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension UIViewController {
    private static var cache = [UIViewController]()
    static var cached: UIViewController {
        if let cached = cache.first(where: { $0.parent == nil }) {
            return cached
        } else {
            let new = UIViewController()
            cache += [new]
            return new
        }
    }
}
