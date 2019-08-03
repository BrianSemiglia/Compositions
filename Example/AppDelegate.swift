/*
 1.  compiler generated concretions
 2.  callbacks custom
 2.5 callbacks native to element
 3.  async nodes
 4.  virtual hierarchies (diffing, rendering, class instead of struct for inheritence?)
 5.  compilation of complex formulas
 6.  pull events (view appearance)
*/

/*
 Navigation scenario

 Observable<Event>
     + .case(.presentingList) + List.self
     + .case(.didSelect) + (
             // alernative: formula produces Node that listens, diffs and updates as needed
             pluck(\Person.firstName) + .black + .instrinsic + .cached
             + .vertical(10)
         )

         + Observable<String> + .black + .instrinsic
         + .vertical(10)
         + String.self + size + Observable.just(.didReceiveText) // Input
*/

/*
 Observable<Event.View>
     + Event.switch
         + \Event.presentingItems
             + Observable<Offset> + Observable<Title>
                 map NavigationBar.withHeightAndTitle
                 + "Add" + .blue + .rightAlignment + .just(.didSelectAdd)

             + .vertical(0)

             + Observable<Offset>
                 map { $0 - 44 }
                 + .just(.didReceiveRefreshRequest)

             + Array<Item>.self
                 \ \Item.icon + size
                    + .horizontal(10)
                    + \Item.title + size
                    + .just(.didSelectItem(\Item.icon)
                 / List
                 + .just(.contentOffset)

             + Observable<[ToolbarItem]>
                 + size
                 + .just(didSelectToolbarItem)
 
         + \Event.didSelectToolbarItem
             + \Item.title + .black + .instrinsic
             + .vertical(10)
 
      / NavigationStack.some
 
 Observable<Event.State>
    + Event.switch
        + \Event.didSelectAdd + NSPersistentContainer(name: "database") + Addition<Item>
        + \Event.didReceiveRefreshRequest + NSPersistentContainer(name: "database") + refresh
        + \Event.didSelectItem + .just(Item.self)
        + \Event.contentOffset + .just(.contentOffset)
        + \Event.didSelectToolbarItem + .just(.didSelectToolbarItem)
 */

/*
 
 [UIImageView.Model] -> cache.freeView.map(decorate($0)) ?? new.decorate($0)
 Does polymorphic approach allows view reuse across nodes?

 Node {
     let cache: Cache<T>
     let initial: Model.empty
     let values: data.map(Model)
     func realized() -> Observable<T> {
         values.map { cache.view.decorated($0) }
     }
 }

 StackView.Model {
     let arranged: [UIView.Model]
     func realized() -> UIStackView {
        let x = UIStackView()
        arranged.forEach {
        x.addArrangedSubview($0.realized())
        return x
     }
 }

// Nodes persist and produce stream. Nodes can retain cache and compose into new node
// zip(a(cache: UIView), b(cache: UIImageView)) { view + .vertical(10) + imageView } -> c(cached: UIStackView)

 zip(Node<UIView.Model>, Node<UIImageView.Model>) { $0 + .vertical(10) + $1 }

 */

import UIKit
import RxSwift

//final class Renderer {
//    private let cache = NSCache<NSString, UIImageView>()
//    func render(_ input: UIImageView.Model) -> UIImageView {
//
//    }
//}
//
//extension UIImageView {
//    struct Model {
//        let image: UIImage
//    }
//    func rendered() -> UIView {
//        return UIImageView(image: image)
//    }
//}

/*
 problem:   don't want to recreate everytime stream produces update
 values:    Node<UIImageView.Model, Void>(cache: UIImageView.cache) ->
            Node<UIImageView.Model, Void>(cache: UIImageView.cache) ->
            Node<Table.Model, Void>(cache: Table.cache)

 */

struct Department: Swift.Decodable {
    let employees: [Person]
    let name: String
}

struct Company: Swift.Decodable {
    let departments: [Department]
}

struct TopLevelThing: Swift.Decodable {
    let address: String
    let companies: [Company]
}

struct Person: Swift.Decodable, Equatable {
    let firstName: String
    let mugshot: URL
    let id: Int
}

final class Events {
    enum Model: Equatable {
        case didSelectPerson(Person)
        //        case didSelectThing(String)
        //        case didSelectYes
        //        case didSelectNo
        //        case didSelectCancel
    }
    static var shared = Events()
    let foo = PublishSubject<Model>()
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let cleanup = DisposeBag()
    let events = PublishSubject<Events.Model>()
    var paged: Lens<[Person], Table<[Person]>>?
    
    /*

     Event -> Data + Constraint -> Concretion -> Event

     (Store / Predicate).map(Decoration) + Size // UITableView

     (Store / (Event(id) + Predicate)).map(Decoration) + Size // UITableView

     */

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

//        NSUInteger cacheSizeMemory = 500*1024*1024; // 500 MB
//        NSUInteger cacheSizeDisk = 500*1024*1024; // 500 MB
        
//        URLCache.shared = URLCache(
//            memoryCapacity: 500*1024*1024,
//            diskCapacity: 500*1024*1024,
//            diskPath: "nsurlcache"
//        )

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: UIViewController())
        window?.makeKeyAndVisible()
        
        events
            .map { (x: Events.Model) -> Person in
                switch x {
                case .didSelectPerson(let y): return y
                }
            }
//            .map { person -> UIView in
//                let x = UIImage(named: "placeholder")!
//                    + CGSize(width: 300, height: 200)
//                    + .vertical(80)
//                    + (
//                        person.firstName
//                            + .foreground(UIColor.black)
//                            + CGSize(width: 300, height: 100)
//                )
//                return x
//            }
            .subscribe(onNext: { [weak self] detail in
                print(detail.firstName)
//                if let navigation = self?.window?.rootViewController.flatMap({ $0 as? UINavigationController }) {
//                    navigation.pushViewController(
//                        [detail] + UIScreen.main.bounds.size,
//                        animated: true
//                    )
//                }
            })
            .disposed(by: cleanup)

//        let x = (
//            URL(string: "https://s3.amazonaws.com/raizlabs-doorman/mugshots/Jess_Caraciolo.JPG")! / UIImage.self
//        ).share(replay: 1, scope: .forever)
//        let y = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 44)
//        let z = Observable.just("hello")
//        let n = .vertical(10) + (x + y + z)
//        let b = Observable.just([n]) / ScreenDivision.some

//        let pages = PageViewController<Events.Model>.example()
////        b.initial.frame = UIScreen.main.bounds
//        window?.rootViewController = pages.initial
//        pages.values.subscribe().disposed(by: cleanup)

//        let table = Table<Events.Model>.example()
//        table.initial.frame = UIScreen.main.bounds
//        window?.rootViewController?.view.addSubview(table.initial)
//        table // table won't load without a subscriber. change table interface to accept Observables and cause subscription? will that affect event subscription?
//            .values
//            .flatMap {
//                $0.1.flatMap {
//                    $0.other.map(Observable.just) ?? .never()
//                }
//            }
//            .bind(to: events)
//            .disposed(by: cleanup)

//        let paged = PageViewController<Events.Model>.example()
//        paged.initial.frame = UIScreen.main.bounds
//        window?.rootViewController?.view.addSubview(paged.initial)
//        paged
//            .subsequent
//            .flatMap { $0.1.debug() }
//            .subscribe(onNext: {
//                self.events.on(.next($0))
//            })
////            .bind(to: events)
//            .disposed(by: cleanup)
        
        let paged = Table<[Person]>
            .exampleLens()
            .subscribingOn { s, v in
                v.rx
                 .willMoveToSuperview
                 .filter { $0 }
                 .take(1)
                 .map { _ in }
            }
        paged.receiver.frame = UIScreen.main.bounds
        window?.rootViewController?.view.addSubview(paged.receiver)
        self.paged = paged
 
//
//                    .zipped {
//                        /* instead of Async<[View]>, try concatenating each with a vertically stacked orientation to build up a table view. Allows nodes.reduce(.empty, zip). */
//                        $0 + [$1]
//                    }
//                    .cacheMap { (sum: UIView?, next: [UIImageView]) in
//                        // Table decides when to pull from cells stream
//                        // Node holds cached concretion
//                        // Table provides number of cells necessary at time of subscribe?
//                        // Table accepts cells as AsyncNodes?
//                        if let table = sum as? Table<Events.Model> {
//                            table.cells = next
//                            return table
//                        } else {
//                            return next + UIScreen.main.bounds.size
//                        }
//                    }
//                    .map {
//                        // need a way to reuse table here
//                        // if model returned instead of concretion, node could
//                        // retain concretion for further updates
//
//                        // Type could also provide a static cache function
//
//                        // Nodes produce Observable<View.Model>, it's realized function uses types cached method
//
//                        $0 + UIScreen.main.bounds.size
//                    }
//            }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

//    func newImageView() -> AsyncNode<UIImageView, Void> {
//        return AsyncNode<UIImageView, Void>(
//            initial: {
//                let x = UIImageView(
//                    frame: CGRect(
//                        origin: .zero,
//                        size: CGSize(
//                            width: 300,
//                            height: 200
//                        )
//                    )
//                )
//                x.widthAnchor.constraint(equalToConstant: 300).isActive = true
//                x.heightAnchor.constraint(equalToConstant: 200).isActive = true
//                x.centerXAnchor.constraint(equalTo: self.window!.rootViewController!.view.centerXAnchor)
//                x.backgroundColor = .yellow
//                return x
//            }(),
//            value: URLSession
//                .shared
//                .rx
//                .data(
//                    request: URLRequest(
//                        url: URL(
//                            string: "https://s3.amazonaws.com/raizlabs-doorman/mugshots/ADRIENNE.jpg"
//                            )!
//                    )
//                )
//                .observeOn(MainScheduler())
//                .map { UIImage(data: $0)! }
//                .map {
//                    let x = $0 + CGSize(width: 300, height: 200)
////                    x.centerXAnchor.constraint(equalTo: self.window!.rootViewController!.view.centerXAnchor)
//                    x.backgroundColor = .red
//                    return x
//                }
////                .startWith({
////                    let x = UIImageView(
////                        frame: CGRect(
////                            origin: .zero,
////                            size: CGSize(
////                                width: 300,
////                                height: 200
////                            )
////                        )
////                    )
//////                    x.widthAnchor.constraint(equalToConstant: 300).isActive = true
//////                    x.heightAnchor.constraint(equalToConstant: 200).isActive = true
//////                    x.centerXAnchor.constraint(equalTo: self.window!.rootViewController!.view.centerXAnchor)
////                    x.backgroundColor = .blue
////                    return x
////                    }()
////            )
//            /*
//
//             */
//            ,
//            callback: Observable<Void>.never()
//        )
//    }
}

//func /(left: Int, right: Int) -> KeyPath<UIViewController, String> {
//    return \.title
//}

//@UIApplicationMain
//class AppDelegate: UIResponder, UIApplicationDelegate {
//
//    var window: UIWindow?
//    let xs = PublishSubject<Int>()
//    let cleanup = DisposeBag()
//
//    func application(
//        _ application: UIApplication,
//        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//    ) -> Bool {
//
//        let a = (String.self + CGSize(width: 200, height: 200))
//            .mapCallback { $0.flatMap { Int($0) } ?? 0 }
////        let n = a
////            .map { $0 + .vertical(100) }
////            .map { $0 + CGFloat.Axis.vertical(100) }
////            .map { $0 }
//        let k = a
////            .map { _ in UIView(frame: UIScreen.main.bounds) }
////            .flatMap { $0 + Observable<String?>.just("hello") }
//            .map { y -> UIViewController in
//                let x = UIViewController()
//                x.view.addSubview(y)
//                y.center = x.view.center
//                y.backgroundColor = .white
//                return x
//            }
////        let z: Node<UIStackView, String?> = CGFloat.Axis.vertical(100) + a
////        let n = z.map { $0 + CGFloat.Axis.vertical(10) }//+ UIScreen.main.bounds
//
//        k.callback
//         .do(onNext: { print($0) })
//         .bind(to: xs)
//         .disposed(by: cleanup)
//
//        window = UIWindow(frame: UIScreen.main.bounds)
//        window?.rootViewController = k.value //+ UIScreen.main.bounds.size
//        window?.makeKeyAndVisible()
//
//        return true
//    }
//
//    func applicationWillResignActive(_ application: UIApplication) {
//        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
//        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
//    }
//
//    func applicationDidEnterBackground(_ application: UIApplication) {
//        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
//        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//    }
//
//    func applicationWillEnterForeground(_ application: UIApplication) {
//        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
//    }
//
//    func applicationDidBecomeActive(_ application: UIApplication) {
//        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//    }
//
//    func applicationWillTerminate(_ application: UIApplication) {
//        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//    }
//
//
//}

