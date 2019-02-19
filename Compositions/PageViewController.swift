//
//  PageViewController.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/17/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit
import RxCocoa

enum PageDivisionHorizontal {
    case some
}

enum PageDivisionVertical {
    case some
}

private func example() {
    _ = [
        UIViewController(),
        [UIViewController(), UIViewController()] / PageDivisionHorizontal.some
    ] / PageDivisionVertical.some
}

func + (left: PageViewController, right: PageDivisionHorizontal) -> (UIViewController) -> PageViewController {
    return { view in
        return (left.model.views + [view]) / right
    }
}

func + (left: PageViewController, right: PageDivisionVertical) -> (UIViewController) -> PageViewController {
    return { view in
        return (left.model.views + [view]) / right
    }
}

func + (left: (UIViewController) -> PageViewController, right: UIViewController) -> PageViewController {
    return left(right)
}

func / (left: [UIViewController], right: PageDivisionHorizontal) -> PageViewController {
    return PageViewController(
        model: .init(
            views: left,
            orientation: .horizontal
        )
    )
}

func + (left: UIViewController, right: PageDivisionHorizontal) -> PageViewController {
    return [left] / right
}

func / (left: [UIViewController], right: PageDivisionVertical) -> PageViewController {
    return PageViewController(
        model: .init(
            views: left,
            orientation: .vertical
        )
    )
}

func + (left: UIViewController, right: PageDivisionVertical) -> PageViewController {
    return [left] / right
}

func + (left: (PageDivisionHorizontal) -> PageViewController, right: PageDivisionHorizontal) -> UIPageViewController {
    return left(right)
}

func + (left: (PageDivisionVertical) -> PageViewController, right: PageDivisionVertical) -> PageViewController {
    return left(right)
}

final class PageViewController: UIPageViewController, UIPageViewControllerDataSource {
    struct Model {
        var views: [UIViewController]
        var orientation: UIPageViewController.NavigationOrientation
    }
    var model: Model {
        didSet {
            render(model: model)
        }
    }
    required init(model: Model) {
        self.model = model
        super.init(
            transitionStyle: .scroll,
            navigationOrientation: model.orientation
        )
        dataSource = self
        setViewControllers(
            model.views.first.map { [$0] },
            direction: .forward,
            animated: false
        )
    }
    func render(model: Model) {
        setViewControllers(
            model.views.first.map { [$0] },
            direction: .forward,
            animated: false
        )
    }
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        return model
            .views
            .firstIndex(of: viewController)
            .map { $0 - 1 }
            .flatMap {
                $0 > 0
                    ? model.views[$0]
                    : Optional<UIViewController>.none
            }
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        return model
            .views
            .firstIndex(of: viewController)
            .map { $0 + 1 }
            .flatMap {
                $0 >= 0 && $0 < model.views.count
                    ? model.views[$0]
                    : Optional<UIViewController>.none
            }
    }
    @available(*, unavailable) required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
