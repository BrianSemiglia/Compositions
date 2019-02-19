import UIKit
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

extension UIColor {
    enum Text {
        case foreground(UIColor)
        case background(UIColor)
    }
}

func + (left: NSAttributedString, right: CGSize) -> UILabel {
    let x = UILabel()
    x.frame = CGRect(origin: .zero, size: right)
    x.attributedText = left
    return x
}

func + (left: NSAttributedString, right: CGSize.Preset) -> UILabel {
    let x = UILabel()
    x.attributedText = left
    switch right {
    case let .manual(w, h):
        x.frame = CGRect(origin: .zero, size: CGSize(width: w, height: h))
    case .intrinsic:
        x.sizeToFit()
    }
    return x
}

extension CGSize {
    enum Preset {
        case manual(CGFloat, CGFloat)
        case intrinsic
    }
}

func + (left: String, right: UIColor.Text) -> NSAttributedString {
    switch right {
    case let .foreground(x):
        return NSAttributedString(
            string: left,
            attributes: [.foregroundColor: x]
        )

    case let .background(x):
        return NSAttributedString(
            string: left,
            attributes: [.backgroundColor: x]
        )
    }
}

func + (left: NSAttributedString, right: UIColor.Text) -> NSAttributedString {
    switch right {
    case let .foreground(x):
        return NSAttributedString(
            string: left.string,
            attributes: [.foregroundColor: x]
        )

    case let .background(x):
        return NSAttributedString(
            string: left.string,
            attributes: [.backgroundColor: x]
        )
    }
}

extension UIColor {
    func combine(_ rhs: UIColor, op: (CGFloat, CGFloat) -> CGFloat) -> UIColor {
        var lhsRed: CGFloat = 0.0
        var lhsGreen: CGFloat = 0.0
        var lhsBlue: CGFloat = 0.0
        var lhsAlpha: CGFloat = 0.0

        self.getRed(
            &lhsRed,
            green: &lhsGreen,
            blue: &lhsBlue,
            alpha: &lhsAlpha
        )

        var rhsRed: CGFloat = 0.0
        var rhsGreen: CGFloat = 0.0
        var rhsBlue: CGFloat = 0.0

        rhs.getRed(
            &rhsRed,
            green: &rhsGreen,
            blue: &rhsBlue,
            alpha: nil
        )

        return UIColor(
            red: op(lhsRed, rhsRed),
            green: op(lhsGreen, rhsGreen),
            blue: op(lhsBlue, rhsBlue),
            alpha: lhsAlpha
        )
    }
}

func +(lhs: UIColor, rhs: UIColor) -> UIColor {
    return lhs.combine(rhs, op: +)
}

func -(lhs: UIColor, rhs: UIColor) -> UIColor {
    return lhs.combine(rhs, op: -)
}

extension CGFloat {
    enum Axis: Equatable {
        case vertical(CGFloat)
        case horizontal(CGFloat)
        func length() -> CGFloat {
            switch self {
            case let .vertical(x): return x
            case let .horizontal(x): return x
            }
        }
    }
}

func + (left: CGFloat.Axis, right: UIView) -> UIStackView {
    let x = UIStackView()
    switch left {
    case .vertical: x.axis = .vertical
    case .horizontal: x.axis = .horizontal
    }
    switch left {
    case let .horizontal(length):
        x.bounds = CGRect(
            origin: .zero,
            size: CGSize(
                width: right.frame.size.width + length,
                height: right.frame.size.height
            )
        )
    case let .vertical(length):
        x.bounds = CGRect(
            origin: .zero,
            size: CGSize(
                width: right.frame.size.width,
                height: right.frame.size.height + length
            )
        )
    }
    switch left {
    case let .horizontal(length):
        x.addArrangedSubview(
            UIView() + .blue + CGSize(width: length, height: 0)
        )
    case let .vertical(length):
        x.addArrangedSubview(
            UIView() + .blue + CGSize(width: 0, height: length)
        )
    }
    x.addArrangedSubview(right)
    return x
}

func + (left: UIView, right: CGFloat.Axis) -> UIStackView {
    let x = UIStackView()
    switch right {
    case .vertical: x.axis = .vertical
    case .horizontal: x.axis = .horizontal
    }

    switch right {
    case let .horizontal(length):
        x.bounds = CGRect(
            origin: .zero,
            size: CGSize(
                width: left.frame.size.width + length,
                height: left.frame.size.height
            )
        )
    case let .vertical(length):
        x.bounds = CGRect(
            origin: .zero,
            size: CGSize(
                width: left.frame.size.width,
                height: left.frame.size.height + length
            )
        )
    }

    x.addArrangedSubview(left)

    switch right {
    case let .horizontal(length):
        x.addArrangedSubview(
            UIView() + .green + CGSize(width: length, height: 0)
        )
    case let .vertical(length):
        x.addArrangedSubview(
            UIView() + .green + CGSize(width: 0, height: length)
        )
    }
    return x
}

func + (left: UIStackView, right: NSLayoutConstraint.Axis) -> UIStackView {
    left.axis = right
    return left
}

func + (left: UIView, right: CGSize) -> UIView {
    left.bounds = CGRect(origin: .zero, size: right)
    return left
}

final class Table: UITableView, UITableViewDataSource {
    let cells: [UIView]
    init(model: [UIView]) {
        cells = model
        super.init(
            frame: .zero,
            style: .plain
        )
        dataSource = self
    }
    @available(*, unavailable) required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell() + cells[indexPath.row]
    }
}

func + (left: [UIView], right: CGSize) -> UIView {
    if (left.reduce(0) { $0 + $1.bounds.size.height }) > right.height {
        return Table(model: left) + right
    } else {
        return (UIStackView() + left) + right
    }
}

func + (left: UIStackView, right: UIView) -> UIStackView {
    left.addArrangedSubview(right)
    return left
}

func + (left: UIStackView, right: [UIView]) -> UIStackView {
    right.forEach {
        left.addArrangedSubview($0)
    }
    left.frame = CGRect(
        origin: .zero,
        size: left.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    )
    return left
}

func + (left: UITableViewCell, right: UIView) -> UITableViewCell {
    left.contentView.addSubview(right)
    right.translatesAutoresizingMaskIntoConstraints = false
    right.topAnchor.constraint(equalTo: left.topAnchor, constant: 0).isActive = true
    right.bottomAnchor.constraint(equalTo: left.bottomAnchor, constant: 0).isActive = true
    right.leadingAnchor.constraint(equalTo: left.leadingAnchor, constant: 0).isActive = true
    right.trailingAnchor.constraint(equalTo: left.trailingAnchor, constant: 0).isActive = true
    return left
}

func + (left: UIView, right: UIColor) -> UIView {
    let background = UIView() + left.bounds.size
    background.addSubview(left)
    background.backgroundColor = right
    return background
}

func + (left: CGSize, right: UIColor) -> UIView {
    return right + left
}

func + (left: UIColor, right: CGSize) -> UIView {
    let x = UIView()
    x.bounds = CGRect(origin: .zero, size: right)
    x.backgroundColor = left
    return x
}

let x = .red + .yellow
let y = "purple" + .foreground(.red + .blue)
let z = "purple" + .foreground(.red + .blue) + .intrinsic
let a = "purple" + .background(.red + .blue) + .intrinsic
let b = z + .horizontal(400) + a + .horizontal(20)
let l = (y + .foreground(.black)) + CGSize.Preset.intrinsic
let s = b + l
let c = ("purple" + .foreground(.red + .blue) + .intrinsic) + .horizontal(100)
let d = .horizontal(300) + c
let e: [UIView] = [
    (.horizontal(100) + ("purple" + .foreground(.red + .blue) + .intrinsic)) + .green,
    (.horizontal(100) + ("yellow" + .background(.red + .yellow) + CGSize(width: 100, height: 200))) + .red
]
let f = e + CGSize(width: 500, height: 200)

// 10 + [.white]
let marginLeft = (.horizontal(10) + (.white + CGSize(width: 10, height: 10))).bounds.size == CGSize(width: 20, height: 10)

// [.white] + 10
let marginRight = ((.white + CGSize(width: 10, height: 10)) + .horizontal(10)).bounds.size == CGSize(width: 20, height: 10)

// 10 + [.white] + 10
let marginLeftRight = ((.horizontal(10) + (.white + CGSize(width: 10, height: 10))) + .horizontal(10)).bounds.size == CGSize(width: 30, height: 10)

// [.white] + (10,10)
let size = (.white + CGSize(width: 10, height: 10)).bounds.size == CGSize(width: 10, height: 10)

// UIView + Margin.h
let hStack = (.red + CGSize(width: 5, height: 50) + .horizontal(50)).bounds.size.width == 55

// UIView + Margin.v
let vStack = (.red + CGSize(width: 5, height: 50) + .vertical(50)).bounds.size.height == 100

// Margin.h + UIView
let hStack2 = (.horizontal(50) + (.red + CGSize(width: 5, height: 50))).bounds.size.width == 55

// Margin.v + UIView
let vStack2 = (.vertical(50) + (.red + CGSize(width: 5, height: 50))).bounds.size.height == 100

// UIStackView + Margin
let vStack3 =
    (.red + CGSize(width: 5, height: 50)) +
    .vertical(50) +
    (.blue + CGSize(width: 5, height: 50))
let vertical3 = vStack3.arrangedSubviews // .reduce(0) { $0 + $1.bounds.size.height } // == 150
print(vertical3)

let stack = ([.white + CGSize(width: 320, height: 10)] + CGSize(width: 320, height: 10)) is UIStackView
let table = ([.white + CGSize(width: 320, height: 11)] + CGSize(width: 320, height: 10)) is UITableView

import SceneKit

// Text + Size + Depth = SCNText

struct Depth {
    let value: CGFloat
}

func + (left: NSAttributedString, right: Depth) -> SCNText {
    return SCNText(
        string: left,
        extrusionDepth: right.value
    )
}

let text3d = "Hello" + .foreground(.yellow) + Depth(value: 2)

// Color + Size -> CALayer
// CALayer + GestureRecognizer -> UIView

import MapKit

struct Earth {
    struct Region {
        let latitude: (center: Double, span: Double)
        let longitude: (center: Double, span: Double)
    }
}

extension MKCoordinateRegion {
    init(center: CLLocationCoordinate2D, span: MKCoordinateSpan) {
        self.init()
        self.center = center
        self.span = span
    }
}

func +(left: Earth.Region, right: CGSize) -> MKMapView { return
    MKMapView()
        + MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: left.latitude.center,
                longitude: left.longitude.center
            ),
            span: MKCoordinateSpan(
                latitudeDelta: left.latitude.span,
                longitudeDelta: left.longitude.span
            )
        )
        + right
}

func +(left: MKMapView, right: CGSize) -> MKMapView {
    left.bounds = .init(
        origin: .zero,
        size: right
    )
    return left
}

func +(left: MKMapView, right: MKCoordinateRegion) -> MKMapView {
    left.region = right
    return left
}

let map = Earth.Region(
              latitude: (center: 42.36, span: 0.125),
              longitude: (center: -71.05, span: 0.125)
          )
          + CGSize(width: 300, height: 100)

func +(left: CLLocationCoordinate2D, right: MKDirectionsTransportType) -> (CLLocationCoordinate2D) -> MKDirections.Request {
    return { destination in
        let x = MKDirections.Request()
        x.source = MKMapItem(
            placemark: MKPlacemark(
                coordinate: left,
                addressDictionary: nil
            )
        )
        x.destination = MKMapItem(
            placemark: MKPlacemark(
                coordinate: destination,
                addressDictionary: nil)
        )
        x.requestsAlternateRoutes = true
        x.transportType = .automobile
        return x
    }
}

func +(left: MKDirections.Request, right: MKDirectionsTransportType) -> (CLLocationCoordinate2D) -> MKDirections.Request {
    return left.destination!.placemark.coordinate + right
}

func +<T, U>(left: (T) -> U, right: T) -> U {
    return left(right)
}

func combined(left: MKDirections.Request, right: MKDirections.Request, completion: @escaping ([MKRoute]) -> Void) {
    MKDirections(request: left).calculate { first, _ in
        if let first = first?.routes {
            MKDirections(request: right).calculate { second, _ in
                completion(
                    first + (second?.routes ?? [])
                )
            }
        }
    }
}

let routes =
    CLLocationCoordinate2D(latitude: 50.0, longitude: -50.0)
        + .walking
        + CLLocationCoordinate2D(latitude: 25.0, longitude: -25.0)
        + .transit
        + CLLocationCoordinate2D(latitude: 24.0, longitude: -24.0)

PlaygroundPage.current.liveView = map


/*
 String + Color + Size                               -> UILabel | UITextView
 String + Color + Size + Depth                       -> SCNText
 String + Color + Size + Callback<Button.Event>      -> UIButton
 String + Color + Size + Callback<String>            -> UITextField | UITextInput
 [String + Color + Size] + Size                      -> UITableView<UILabel> | UICollectionView<UILabel>
 Location + TransportType + Location                 -> Route
 CoordinateRegion + Size                             -> MKMapView
 Store + Predicate<String>                           -> [String]
 Store + Account + Predicate<String>                 -> Observable<[String]>
 UIView + PartiallyOverlapping + UIView              -> UINavigationController
 UIView + PhysicalPagesOne + UIView                  -> UIPageViewController
 UIView + PhysicalPagesTwo + UIView                  -> UIPageViewController
 UIView + SlideyMode + UIView                        -> UIPageViewController // infix won't work with style due to all of nothing per uipageviewcontroller. so either don't use UIPVC or use different implementation
 Size.sidLength

 Date + Date.Range + Size.Auto                       -> UIDatePicker // how to deal with immutable defaults

 UINavigationController + UIView + PresentationModal -> UINavigationController

 // UIViewController<UICollectionView<UILabel>>
 // Screen bounds can be potentially used to limit query batch size
 window.rootViewController = (Store + Predicate<String>).map(+ Color).map(+ Size) + UIScreen.main.bounds

 */


[1,2,3].cycled.map(+ size).map( $0 + sequential ) // page view controller
