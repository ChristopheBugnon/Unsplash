//
//  EndPoint.swift
//  UnsplashFeed
//
//  Created by Christophe Bugnon on 07/11/2023.
//

import Foundation

public enum EndPoint {
    case photos(page: Int)

    public func url() -> URL {
        let baseURL = URL(string: "https://api.unsplash.com/")!
        
        switch self {
        case .photos(let page):
            var components = URLComponents()
            components.scheme = baseURL.scheme
            components.host = baseURL.host
            components.path = baseURL.path + "photos"
            components.queryItems = [
                URLQueryItem(name: "page", value: String(page)),
            ]
            return components.url!
        }
    }
}
