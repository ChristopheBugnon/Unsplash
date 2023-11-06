//
//  RemoteFeedLoaderTests.swift
//  UnsplashFeedTests
//
//  Created by Christophe Bugnon on 06/11/2023.
//

import XCTest
import UnsplashFeed

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(string: "http://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(.connectivity), when: {
            let clientError = NSError(domain: "Client error", code: 0)
            client.complete(with: clientError)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400]
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .failure(.invalidData), when: {
                client.complete(withStatusCode: code, at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(.invalidData), when: {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .success([]), when: {
            let emptyJSONList = Data("[]".utf8)
            client.complete(withStatusCode: 200, data: emptyJSONList)
        })
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        
        let profile1 = ProfileItem(id: UUID().uuidString,
                                   name: "a name",
                                   username: "a username",
                                   imageURL: URL(string: "http://a-profile-image-url.com")!)
        let item1 = FeedItem(id: UUID().uuidString,
                             description: "a title",
                             imageURL: URL(string: "http://an-image-url.com")!,
                             likes: 0,
                             profile: profile1)
        let profile1JSON: [String: Any] = [
            "id": profile1.id,
            "name": profile1.name,
            "username": profile1.username,
            "profile_image": ["medium": profile1.imageURL.absoluteString]
        ]
        let item1JSON: [String: Any] = [
            "id": item1.id,
            "description": item1.description,
            "urls": ["small": item1.imageURL.absoluteString],
            "likes": item1.likes,
            "user": profile1JSON
        ]
        
        let profile2 = ProfileItem(id: UUID().uuidString,
                                   name: "another name",
                                   username: "another username",
                                   imageURL: URL(string: "http://a-profile-image-url.com")!)
        let item2 = FeedItem(id: UUID().uuidString,
                             description: nil,
                             imageURL: URL(string: "http://another-image-url.com")!,
                             likes: 1,
                             profile: profile2)
        let profile2JSON: [String: Any] = [
            "id": profile2.id,
            "name": profile2.name,
            "username": profile2.username,
            "profile_image": ["medium": profile2.imageURL.absoluteString]
        ]
        let item2JSON: [String: Any] = [
            "id": item2.id,
            "urls": ["small": item2.imageURL.absoluteString],
            "likes": item2.likes,
            "user": profile2JSON
        ]
        
        let items = [item1, item2]
        let jsonItems = [item1JSON, item2JSON]
        
        expect(sut, toCompleteWith: .success(items), when: {
            let itemsJSONList = try! JSONSerialization.data(withJSONObject: jsonItems)
            client.complete(withStatusCode: 200, data: itemsJSONList)
        })
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "http://any-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith result: RemoteFeedLoaderResult, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        var capturedResults = [RemoteFeedLoaderResult]()
        sut.load { capturedResults.append($0) }
        
        action()
        
        XCTAssertEqual(capturedResults, [result], file: file, line: line)
    }
    
    final class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedURLs: [URL] {
            return messages.map(\.url)
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index],
                                           statusCode: code,
                                           httpVersion: nil,
                                           headerFields: nil)!
            messages[index].completion(.success((data, response)))
        }
    }
}
