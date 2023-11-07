//
//  FeedItemsMapper.swift
//  UnsplashFeed
//
//  Created by Christophe Bugnon on 06/11/2023.
//

import Foundation

final class FeedItemsMapper {
    private init() {}
    
    private static let OK_200 = 200
    
    static func map(_ data: Data, response: HTTPURLResponse) -> LoadFeedResult {
        guard response.statusCode == OK_200,
              let remoteItems = try? JSONDecoder().decode([RemoteFeedItem].self, from: data) else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }
        return .success(remoteItems.map(\.item))
    }
    
    // MARK: - Remote contract items
    
    private struct RemoteFeedItem: Decodable {
        let id: String
        let description: String?
        let imageURL: URL
        let likes: Int
        let profile: RemoteProfileItem
        
        var item: FeedItem {
            return FeedItem(id: id,
                            description: description,
                            imageURL: imageURL,
                            likes: likes,
                            profile: profile.item)
        }
        
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
            profile = try container.decode(RemoteProfileItem.self, forKey: .user)
            likes = try container.decode(Int.self, forKey: .likes)
        }
    }
    
    
    private struct RemoteProfileItem: Decodable {
        let id: String
        let name: String
        let username: String
        let imageURL: URL
        
        var item: ProfileItem {
            return ProfileItem(id: id,
                               name: name,
                               username: username,
                               imageURL: imageURL)
        }
        
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


}
