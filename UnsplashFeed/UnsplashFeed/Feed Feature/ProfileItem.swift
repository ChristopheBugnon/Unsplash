//
//  ProfileItem.swift
//  UnsplashFeed
//
//  Created by Christophe Bugnon on 06/11/2023.
//

import Foundation

public struct ProfileItem: Equatable, Hashable {
    public let id: String
    public let name: String
    public let username: String
    public let imageURL: URL
    
    public init(id: String, name: String, username: String, imageURL: URL) {
        self.id = id
        self.name = name
        self.username = username
        self.imageURL = imageURL
    }
}

extension ProfileItem: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case username
        case imageURL = "profile_image"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        username = try container.decode(String.self, forKey: .username)
        let urls = try container.decode([String: URL].self, forKey: .imageURL)
        imageURL = urls["medium"]!
    }
}
