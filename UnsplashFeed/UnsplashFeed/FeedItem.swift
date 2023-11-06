//
//  FeedItem.swift
//  UnsplashFeed
//
//  Created by Christophe Bugnon on 06/11/2023.
//

import Foundation

public struct FeedItem: Equatable, Hashable {
    public let id: String
    public let title: String?
    public let imageURL: URL
    public let likes: Int
    public let profile: ProfileItem

    public init(id: String, title: String?, imageURL: URL, likes: Int, profile: ProfileItem) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.likes = likes
        self.profile = profile
    }
}
