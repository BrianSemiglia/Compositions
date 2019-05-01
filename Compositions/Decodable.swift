//
//  Decodable.swift
//  Compositions
//
//  Created by Zev Eisenberg on 2/16/19.
//  Copyright © 2019 Zev Eisenberg. All rights reserved.
//

import RxSwift
import RxCocoa
import Alamofire
import RxAlamofire

func + (left: URL, right: URLRequest.CachePolicy) -> URLRequest { return
    URLRequest(url: left, cachePolicy: right, timeoutInterval: 60.0)
}

func / <T: Decodable>(left: URLRequest, right: T.Type) -> Observable<T> {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return URLSession
        .shared
        .rx
        .data(request: left)
        //        .debug("response!", trimOutput: false)
        .map { try decoder.decode(right, from: $0) }
}

func / <T: Decodable>(left: URL, right: T.Type) -> Observable<T> {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return URLSession
        .shared
        .rx
        .data(request: URLRequest(url: left))
        //        .debug("response!", trimOutput: false)
        .map { try decoder.decode(right, from: $0) }
}

func / (left: URL, right: UIImage.Type) -> Observable<UIImage> {
    return autoreleasepool {
//        requestData(URLRequest(url: left))
//        .map { $0.1 }
        var session = URLSession.shared
        return session.rx
            .data(request: URLRequest(url: left))
            .subscribeOn(MainScheduler.instance)
            .do(onCompleted: { [weak session] in
//                session?.finishTasksAndInvalidate()
//                session = nil
//                _ = autoreleasepool { UIImage(data: x) }
            })
            .map { x in
                autoreleasepool { UIImage(data: x) }
//                return Optional<UIImage>.none
            }
            .flatMap { $0.map(Observable.just) ?? .never() }
    }
}
