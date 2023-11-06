//
//  RemoteFeedLoaderTests.swift
//  UnsplashFeedTests
//
//  Created by Christophe Bugnon on 06/11/2023.
//

import XCTest

final class HTTPClient {
    var requestedURL: URL?
}

final class RemoteFeedLoader {
    
}

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClient()
        _ = RemoteFeedLoader()
        
        XCTAssertNil(client.requestedURL)
    }
}
