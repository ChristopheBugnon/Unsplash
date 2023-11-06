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
