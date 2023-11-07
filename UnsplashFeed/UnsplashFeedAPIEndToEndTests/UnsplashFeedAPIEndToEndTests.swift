//
//  UnsplashFeedAPIEndToEndTests.swift
//  UnsplashFeedAPIEndToEndTests
//
//  Created by Christophe Bugnon on 07/11/2023.
//

import XCTest
import UnsplashFeed

final class UnsplashFeedAPIEndToEndTests: XCTestCase {

    func test_endToEndTestServerGETFeedResult() {
        let url = URL(string: "https://api.unsplash.com/photos")!
        let client = URLSessionHTTPClient()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        let exp = expectation(description: "Wait for load completion")
        var receivedResult: LoadFeedResult?
        sut.load { result in
            receivedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 5.0)
        
        switch receivedResult {
        case let .success(items):
            XCTAssertEqual(items.count, 10)
            
        case let .failure(error):
            XCTFail("Expected successfull feed result, got error \(error) instead")
            
        default:
            XCTFail("Expected successfull feed result, got no result instead")
        }
    }

}
