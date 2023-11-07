//
//  URLSessionHTTPClientTests.swift
//  UnsplashFeedTests
//
//  Created by Christophe Bugnon on 07/11/2023.
//

import XCTest
import UnsplashFeed

final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct UnexpectedValuesRepresentation: Error {}
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error {
                completion(.failure(error))
            } else if let data, data.count > 0, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        URLProtocolStub.startInterceptingRequest()
    }
    
    override func tearDown() {
        super.tearDown()
        
        URLProtocolStub.stopInterceptingRequest()
    }
    
    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyURL()
        let exp = expectation(description: "Wait for observe request completion")
        
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            
            exp.fulfill()
        }
        
        makeSUT().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let expectedError = anyNSError()
        
        let receivedError = resultErrorFor(data: nil, response: nil, error: expectedError)
        
        XCTAssertEqual(receivedError?.domain, expectedError.domain)
        XCTAssertEqual(receivedError?.code, expectedError.code)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        let data = Data("any data".utf8)
        let nonHTTPURLResponse = URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let anyHTTPURLResponse = HTTPURLResponse(url: anyURL(), statusCode: 0, httpVersion: nil, headerFields: nil)
        
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: data, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: data, response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: data, response: nonHTTPURLResponse, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: data, response: anyHTTPURLResponse, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: data, response: nonHTTPURLResponse, error: nil))
    }
    
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        let url = anyURL()
        let data = Data("any data".utf8)
        let response = HTTPURLResponse(url: url, statusCode: 0, httpVersion: nil, headerFields: nil)!
        URLProtocolStub.stub(data: data, response: response, error: nil)
        
        let exp = expectation(description: "Wait for get completion")
        makeSUT().get(from: url) { result in
            switch result {
            case let .success((receivedData, receivedResponse)):
                XCTAssertEqual(receivedData, data)
                XCTAssertEqual(receivedResponse.url, response.url)
                XCTAssertEqual(receivedResponse.statusCode, response.statusCode)

            default:
                XCTFail("Exepcted success, got \(result) result instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> NSError? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        let exp = expectation(description: "Wait for get completion")
        var receivedError: NSError?
        
        makeSUT().get(from: anyURL()) { result in
            switch result {
            case let .failure(error as NSError):
                receivedError = error
                
            default:
                XCTFail("Expected failure, but got \(result) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
        
        return receivedError
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "Any error", code: 0)
    }
    
    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
    
    private final class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var observer: ((URLRequest) -> Void)?
        
        struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func observeRequest(_ observer: @escaping (URLRequest) -> Void) {
            URLProtocolStub.observer = observer
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func startInterceptingRequest() {
            URLProtocolStub.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequest() {
            URLProtocolStub.unregisterClass(URLProtocolStub.self)
            stub = nil
            URLProtocolStub.observer = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            URLProtocolStub.observer?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
