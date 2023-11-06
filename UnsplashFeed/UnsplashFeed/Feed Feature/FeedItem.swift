//
//  FeedItem.swift
//  UnsplashFeed
//
//  Created by Christophe Bugnon on 06/11/2023.
//

import Foundation

public struct FeedItem: Equatable, Hashable {
    public let id: String
    public let description: String?
    public let imageURL: URL
    public let likes: Int
    public let profile: ProfileItem

    public init(id: String, description: String?, imageURL: URL, likes: Int, profile: ProfileItem) {
        self.id = id
        self.description = description
        self.imageURL = imageURL
        self.likes = likes
        self.profile = profile
    }
}
