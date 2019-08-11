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
    var lens: Cycled<UIViewController, String>?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        self.lens = Cycled { stream in
            let textView = stream.lens(
                get: { state in
                    UITextView().rendering(state) { view, state in
                        view.frame = .init(
                            origin: .init(x: 30, y: 60),
                            size: .init(width: 300, height: 44)
                        )
                        view.text = state
                        view.backgroundColor = state.count % 2 == 0 ? .yellow : .red
                    }
                },
                set: { view, state in
                    view.rx.text.map { $0 ?? "" }
                }
            )

            let background = stream.lens(
                get: { state -> UIView in
                    UIView().rendering(state) { view, state in
                        view.backgroundColor = state.count % 2 == 0 ? .red : .yellow
                    }
                },
                set: { _, _ in [] } // error(Foo.some) }
            )

            let composedView = textView
                .zip(background)
                .map { state, views -> UIView in
                    views.1.addSubview(views.0)
                    return views.1
                }

            let composedViewController = composedView
                .map { state, view -> UIViewController in
                    let x = UIViewController()
                    x.view = view
                    return x
                }
                .prefixed(with: .just("hello"))

            return composedViewController
        }

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        window?.rootViewController = self.lens?.receiver

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

