//
//  TableView.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/16/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Differ

enum ListDivision {
    case some
}

extension Table {
    static func example() -> AsyncNode<Table<Events.Model>, Table<Events.Model>.Event> { return
        (URL(string: "https://rzdoorman.herokuapp.com/api/v1/facilities/14")! / TopLevelThing.self)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .flatMap { thing in
                Observable<Int>
                    .interval(
                        5.0,
                        scheduler: MainScheduler()
                    )
                    .map { _ in }
                    .startWith(())
                    .map {
                        thing
                            .companies
                            .flatMap { $0.departments }
                            .flatMap { $0.employees }
                            .shuffled()
                    }
            }
            .debug()
            .observeOn(MainScheduler.instance)
            .map { people in
                people.map { person in
                    let x = (person.mugshot / UIImage.self)
                    let y = CGSize(width: UIScreen.main.bounds.width, height: 300)
                    let z = Observable.just(Events.Model.didSelectPerson(person))
                    return (x + y + z).map { Hashed(id: person.id, value: $0) }
                }
            }
            / ListDivision.some
    }
}

struct Hashed<T> {
    let id: AnyHashable
    let value: T
}

func / <T>(
    left: Observable<[AsyncNode<Hashed<UIView>, T>]>,
    right: ListDivision
) -> AsyncNode<Table<T>, Table<T>.Event> {
    let x = Table<T>(cells: [])
    return AsyncNode(
        initial: x,
        values: left.map { x.cells = $0; return (x, x.callbacks); }
    )
}

final class Table<T>: UITableView, UITableViewDataSource, UITableViewDelegate {

    enum Event {
        case contentOffset(CGPoint)
        case other(T)
        var contentOffset: CGPoint? {
            switch self {
            case .contentOffset(let x): return x
            case _: return nil
            }
        }
        var other: T? {
            switch self {
            case .other(let x): return x
            case _: return nil
            }
        }
    }

    let callbacks = PublishSubject<Event>()
    var cells: [AsyncNode<Hashed<UIView>, T>] {
        didSet {
            animateRowAndSectionChanges(
                oldData: [oldValue.map { $0.initial.id }],
                newData: [cells.map { $0.initial.id }],
                rowDeletionAnimation: DiffRowAnimation.fade,
                rowInsertionAnimation: DiffRowAnimation.top,
                sectionDeletionAnimation: DiffRowAnimation.fade,
                sectionInsertionAnimation: DiffRowAnimation.top
            )
        }
    }
    private var visiblePresentations: [UIView: DisposeBag] = [:]
    private var visibleCallbacks: [UIView: DisposeBag] = [:]
    private let cleanup = DisposeBag()

    init(cells: [AsyncNode<Hashed<UIView>, T>], frame: CGRect = .zero) {
        self.cells = cells
        super.init(
            frame: frame,
            style: .plain
        )
        dataSource = self
        delegate = self
        prefetchDataSource = nil
        rx
            .contentOffset
            .map(Event.contentOffset)
            .bind(to: callbacks)
            .disposed(by: cleanup)
    }
    
    @available(*, unavailable) required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        let whileVisible = DisposeBag()
        // too many cells loaded on init and being retained; this is causing duplicate callbacks
        visiblePresentations[cell] = whileVisible
        cells[indexPath.row]
            .values
            .subscribe(onNext: { [weak self] content, callbacks in
                if let `self` = self {
                    let new = DisposeBag()
                    self.visibleCallbacks[content.value] = new
                    callbacks.map(Event.other).bind(to: self.callbacks).disposed(by: new)
                    content.value.translatesAutoresizingMaskIntoConstraints = false
                    cell.contentView.addSubview(content.value)
                    content.value.topAnchor.constraint(equalTo: cell.contentView.topAnchor).isActive = true
                    content.value.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor).isActive = true
                    content.value.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor).isActive = true
                    content.value.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor).isActive = true
                }
            })
            .disposed(by: whileVisible)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "id")
        return tableView.dequeueReusableCell(withIdentifier: "id", for: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cells.map { $0.initial.value }[indexPath.row].bounds.height
    }
}

func + (left: UITableViewCell, right: UIView) -> UITableViewCell {
    left.contentView.addSubview(right)
    right.translatesAutoresizingMaskIntoConstraints = false
    right.topAnchor.constraint(equalTo: left.contentView.topAnchor, constant: 0).isActive = true
    right.bottomAnchor.constraint(equalTo: left.contentView.bottomAnchor, constant: 0).isActive = true
    right.leadingAnchor.constraint(equalTo: left.contentView.leadingAnchor, constant: 0).isActive = true
    right.trailingAnchor.constraint(equalTo: left.contentView.trailingAnchor, constant: 0).isActive = true
    return left
}
