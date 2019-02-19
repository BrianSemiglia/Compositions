//
//  Decodable.swift
//  Compositions
//
//  Created by Zev Eisenberg on 2/16/19.
//  Copyright © 2019 Zev Eisenberg. All rights reserved.
//

import RxSwift

func +<T: Decodable>(left: URL, right: T.Type) -> Single<T> {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return URLSession
        .shared
        .rx
        .data(request: URLRequest(url: left))
        .map { try decoder.decode(right, from: $0) }
        .asSingle()
}
