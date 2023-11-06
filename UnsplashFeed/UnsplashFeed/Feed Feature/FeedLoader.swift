//
//  FeedLoader.swift
//  UnsplashFeed
//
//  Created by Christophe Bugnon on 06/11/2023.
//

import Foundation

protocol FeedLoader {
    func load(completion: @escaping (Swift.Result<[FeedItem], Error>) -> Void)
}
