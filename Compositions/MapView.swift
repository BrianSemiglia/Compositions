//
//  MapView.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/19/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import MapKit
import RxSwift

private func exampleRegion() -> MKMapView { return
    Earth.Region(
        latitude: (center: 42.36, span: 0.125),
        longitude: (center: -71.05, span: 0.125)
    )
    + CGSize(width: 300, height: 100)
}

struct Earth {
    struct Region {
        let latitude: (center: Double, span: Double)
        let longitude: (center: Double, span: Double)
    }
}

func + (left: CLLocationCoordinate2D, right: MKCoordinateSpan) -> MKCoordinateRegion {
    var x = MKCoordinateRegion()
    x.center = left
    x.span = right
    return x
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
        + (
            CLLocationCoordinate2D(
                latitude: left.latitude.center,
                longitude: left.longitude.center
            )
            + MKCoordinateSpan(
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
