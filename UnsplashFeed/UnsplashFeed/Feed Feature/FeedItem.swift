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

extension FeedItem: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case description
        case urls
        case user
        case likes
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        let urls = try container.decode([String: URL].self, forKey: .urls)
        imageURL = urls["small"]!
        profile = try container.decode(ProfileItem.self, forKey: .user)
        likes = try container.decode(Int.self, forKey: .likes)
    }
}
