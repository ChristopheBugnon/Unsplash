//
//  FeedLoader.swift
//  UnsplashFeed
//
//  Created by Christophe Bugnon on 06/11/2023.
//

import Foundation

public typealias LoadFeedResult = Swift.Result<[FeedItem], Error>

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
