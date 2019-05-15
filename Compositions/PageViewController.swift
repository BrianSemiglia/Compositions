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

/*
 implement:
 
 items
 map repeat 4 divided Pages.horizontal
 divided List
 */

extension PageViewController {
    static func example() -> AsyncNode<PageViewController<Events.Model>, Events.Model> {
        let x = (URL(string: "https://rzdoorman.herokuapp.com/api/v1/facilities/14")! / TopLevelThing.self)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map { $0
                .companies
                .flatMap { $0.departments }
                .flatMap { $0.employees }
            }
            .map { $0.prefix(5) }
            .observeOn(MainScheduler.instance)
            .map { people in
                people
                    .reduce([[Person]]()) { $0 + [[$1, $1]] }
                    .map { collection -> [AsyncNode<UIView, Events.Model>] in
                        collection.map { person -> AsyncNode<UIView, Events.Model> in
                            let x = (person.mugshot / UIImage.self)//.share(replay: 1, scope: .forever)
                            let y = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 44)
                            let z = Observable.just(Events.Model.didSelectPerson(person))
                            let n = (x + y + z)
                            return n
                        }
                    }
                    .map { $0 / PageDivision.horizontal }
                    .map { $0.map { $0 as UIView } }

                        //                        .map { // was causing duplicate initial events
                        //                            $0
                        //                                + .vertical(10)
                        //                                + (
                        //                                    person.firstName
                        //                                        + .foreground(.green)
                        //                                        + CGSize(width: UIScreen.main.bounds.width, height: 44.0)
                        //                                )
                        //                        }
                    }
//                .reduce([]) { sum, next in
//                      sum + [([next, next, next] / PageDivision.horizontal)]
//                }
//        }
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
//            x.begin()
            return (
                x,
                x.callbacks
            )
        }
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
    // Both PVCs need updates.
    // Outer pulls to receive new array?
    // Inner pulls to receive image?
    // Two pulls means two network requests?
    // Generic way to resolve? map?
    // OR
    // viewWillAppear called redundantly. way to ignore and prevent redundant subscriptions?
    // if pageview accepted observable as model it could pass without subscribing?
    
    /*
     [[1], [1]] -> subscribePages -> subscribePage
     [[Node], [Node]]
     */
    
    return AsyncNode(
        initial: x,
        values: Observable.just(left).map {
            x.pages = $0;
            return (
                x,
                x.callbacks
            )
        }
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

final class PageViewController<T>: UIView, UIPageViewControllerDataSource {

    let callbacks = PublishSubject<T>()
    private let pageViewController: UIPageViewController
    private let cleanup = DisposeBag()
    private var events: Disposable?
    private var firstLoadDidHappen = false

    var pages: [AsyncNode<UIView, T>] = [] { // nodes are retaining memory?
        didSet {
            render(model: pages)
//            render(model: pages)
        }
    }
//    private var views: [AsyncViewController<T>]
    
    required init(model: [AsyncNode<UIView, T>], orientation: UIPageViewController.NavigationOrientation) {
        pages = model
//        views = model.map {
//            let x = AsyncViewController(model: $0.values)
//            x.view.backgroundColor = .white
//            return x
//        }
//        Observable COMMENTING OUT FIXES CALLBACK ISSUE. BINDING TWICE SEEMS TO CAUSE ISSUE.
//            .merge(views.map { $0.callbacks })
//            .bind(to: callbacks)
//            .disposed(by: cleanup)
        pageViewController = .init(
            transitionStyle: .scroll,
            navigationOrientation: orientation
        )
        super.init(frame: UIScreen.main.bounds)

        pageViewController.dataSource = self
        addSubview(pageViewController.view)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        pageViewController.view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        pageViewController.view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        pageViewController.view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        pageViewController.view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
//        if let first = pages.first {
//            let x = AsyncViewController(model: first.values, index: 0)
////            x.begin()
//            pageViewController.setViewControllers(
//                [x],
//                direction: .forward,
//                animated: false
//            )
//        }
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
//        if newWindow != nil {
//            views.first?.begin()
//        }
    }
    
//    func begin() {
//        if let x = pageViewController.viewControllers?.first as? AsyncViewController<T> {
//            x.begin()
//        }
//    }
    
    func render(model: [AsyncNode<UIView, T>]) {
//        views = model.map {
//            let x = AsyncViewController(model: $0.values)
//            x.view.backgroundColor = .white
//            return x
//        }
//        events = Observable
//            .merge(pages.map { $0.callbacks })
//            .debug()
////            .subscribe()
//            .bind(to: callbacks)
//            .disposed(by: cleanup)
//        views.first?.begin()
        if let first = pages.first {
            let x = AsyncViewController(model: first.values, index: 0)
            events = x.callbacks.subscribe(onNext: {
                self.callbacks.on(.next($0))
            })
            x.begin()
            pageViewController.setViewControllers(
                [x],
                direction: .forward,
                animated: false
            )
        }
//        pageViewController.setViewControllers(
//            views.first.map { [$0] } ?? [],
//            direction: .forward,
//            animated: false
//        )
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        if let input = viewController as? AsyncViewController<T> {
            
            input.end()
            let new = input.index > 0
                ? AsyncViewController(
                    model: pages[input.index - 1].values,
                    index: input.index - 1
                )
                : Optional<AsyncViewController<T>>.none
            
            new?.callbacks.subscribe(onNext: {
                self.callbacks.on(.next($0))
            })
            new?.begin()
            return new
            
//            return views
//                .firstIndex(of: input)
//                .map { $0 - 1 }
//                .flatMap {
//                    $0 >= 0
//                        ? views[$0]
//                        : Optional<AsyncViewController<T>>.none
//                }
//                .map { $0.begin(); return $0; }
        } else {
            return nil
        }
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        if let input = viewController as? AsyncViewController<T> {
            
            input.end()
            let new = input.index < pages.count - 1
                ? AsyncViewController(
                    model: pages[input.index + 1].values,
                    index: input.index + 1
                )
                : Optional<AsyncViewController<T>>.none
            
            new?.callbacks.subscribe(onNext: {
                self.callbacks.on(.next($0))
            })
            new?.begin()
            return new
            
//            input.end()
//            return views
//                .firstIndex(of: input)
//                .map { $0 + 1 }
//                .flatMap {
//                    $0 >= 0 && $0 < views.count
//                        ? views[$0]
//                        : Optional<AsyncViewController<T>>.none
//                }
//                .map { $0.begin(); return $0; }
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
    let index: Int
    
    init(model: Observable<(UIView, Observable<T>)>, index: Int) {
        self.index = index
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    func begin() {
        _presentation?.dispose()
        _presentation = model.subscribe(onNext: { [weak self] in
            if let `self` = self {
//                self._callback?.dispose()
                self.view.subviews.forEach { $0.removeFromSuperview() }
                self._callback = $0.1
//                    .bind(to: self.callbacks)
                .subscribe(onNext: { [weak self] in
                    self?.callbacks.on(.next($0))
                })
//                self._callback = new
//                self.cleanup.insert(new)
                $0.0.frame = self.view.bounds
                self.view.addSubview($0.0)
            }
        })
    }
    
    func end() {
        _callback?.dispose()
        _presentation?.dispose()
//        view.subviews.forEach { $0.removeFromSuperview() }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        if let window = view.window, window.frame.contains(view.convert(view.frame, to: view.window)) {
//            begin()
//        }
//        begin()
//        _presentation?.dispose()
//        _presentation = model.subscribe(onNext: { [weak self] in
//            if let `self` = self {
////                self._callback?.dispose()
//                self.view.subviews.forEach { $0.removeFromSuperview() }
////                self._callback = $0.1.bind(to: self.callbacks)
////                subscribe(onNext: { [weak self] in
////                    self?.callbacks.on(.next($0))
////                })
////                self._callback = new
////                self.cleanup.insert(new)
//                $0.0.frame = self.view.bounds
//                self.view.addSubview($0.0)
//            }
//        })
//        _presentation = new
//        cleanup.insert(new)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
//        end()
//        _callback?.dispose()
//        _presentation?.dispose()
//        view.subviews.forEach { $0.removeFromSuperview() }
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
