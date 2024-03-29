//
//  LoadFeedFromRemoteUseCaseTests.swift
//  UnsplashFeedTests
//
//  Created by Christophe Bugnon on 06/11/2023.
//

import XCTest
import UnsplashFeed

final class LoadFeedFromRemoteUseCaseTests: XCTestCase {
    
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
        
        expect(sut, toCompleteWith: failure(.connectivity), when: {
            let clientError = NSError(domain: "Client error", code: 0)
            client.complete(with: clientError)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400]
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData), when: {
                let emptyJSONList = Data("[]".utf8)
                client.complete(withStatusCode: code, data: emptyJSONList, at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.invalidData), when: {
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
        
        let items = [
            makeItem(description: nil, likes: 0),
            makeItem(description: "any description", likes: 1)
        ]
        
        expect(sut, toCompleteWith: .success(items.map(\.model)), when: {
            let itemsJSONList = try! JSONSerialization.data(withJSONObject: items.map(\.json))
            client.complete(withStatusCode: 200, data: itemsJSONList)
        })
    }
    
    func test_load_doesNotDeliversResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "http://any-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        var capturedResults = [LoadFeedResult]()
        sut?.load(completion: { capturedResults.append($0) })
        
        sut = nil
        client.complete(with: NSError(domain: "Any error", code: 0))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func failure(_ error: RemoteFeedLoader.Error) -> LoadFeedResult {
        return .failure(error)
    }
    
    private func makeItem(description: String?, likes: Int) -> (model: FeedItem, json: [String: Any]) {
        let profileId = UUID().uuidString
        let profile = ProfileItem(id: profileId,
                                   name: "\(profileId) a name",
                                   username: "\(profileId) a username",
                                   imageURL: URL(string: "http://a-profile-image-url-id-\(profileId).com")!)
        let itemId = UUID().uuidString
        let item = FeedItem(id: itemId,
                             description: "\(itemId) a title",
                             imageURL: URL(string: "http://an-image-url-id-\(itemId).com")!,
                             likes: likes,
                             profile: profile)
        let profileJSON: [String: Any] = [
            "id": profile.id,
            "name": profile.name,
            "username": profile.username,
            "profile_image": ["medium": profile.imageURL.absoluteString]
        ]
        let itemJSON = [
            "id": item.id,
            "description": item.description as Any,
            "urls": ["small": item.imageURL.absoluteString],
            "likes": item.likes,
            "user": profileJSON
        ].compactMapValues { $0 }
        
        return (item, itemJSON)
    }
    
    private func makeSUT(url: URL = URL(string: "http://any-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith expectedResult: LoadFeedResult, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")
        
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success(let receivedItems), .success(let expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
                
            case (.failure(let receivedError as RemoteFeedLoader.Error), .failure(let expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            default:
                XCTFail("Expected result \(expectedResult), but got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
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
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index],
                                           statusCode: code,
                                           httpVersion: nil,
                                           headerFields: nil)!
            messages[index].completion(.success((data, response)))
        }
    }
}
