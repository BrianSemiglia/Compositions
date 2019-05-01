//
//  MKDirections.swift
//  Compositions
//
//  Created by Brian Semiglia on 2/19/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import MapKit
import RxSwift
import RxCallbacks

func example() -> Observable<MKDirections.Response> { return
    CLLocationCoordinate2D(latitude: 50.0, longitude: -50.0)
        + .walking
        + CLLocationCoordinate2D(latitude: 25.0, longitude: -25.0)
        + .transit
        + CLLocationCoordinate2D(latitude: 24.0, longitude: -24.0)
        + .transit
        + CLLocationCoordinate2D(latitude: 24.0, longitude: -24.0)
}

func +(left: CLLocationCoordinate2D, right: MKDirectionsTransportType) -> (CLLocationCoordinate2D) -> Observable<MKDirections.Response> {
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
        x.transportType = right
        return Observable<Optional<MKDirections.Response>>
            .fromCallback(MKDirections(request: x).calculate)
            .take(1)
            .flatMap {
                $0.0.map { $0 }.map(Observable.just)
                    ?? $0.1.map(Observable.error)
                    ?? .never()
            }
    }
}

func +(left: MKDirections.Request, right: MKDirectionsTransportType) -> (CLLocationCoordinate2D) -> Observable<MKDirections.Response> {
    return left.destination!.placemark.coordinate + right
}

func + (left: (CLLocationCoordinate2D) -> Observable<MKDirections.Response>, right: CLLocationCoordinate2D) -> Observable<MKDirections.Response> {
    return left(right)
}

func + (left: Observable<MKDirections.Response>, right: MKDirectionsTransportType) -> (CLLocationCoordinate2D) -> Observable<MKDirections.Response> {
    return { location in
        left.concatMap { x in
            Observable.merge(
                Observable.just(x),
                x.destination.placemark.coordinate + right + location
            )
        }
    }
}
