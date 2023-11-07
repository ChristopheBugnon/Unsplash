//
//  URLSessionHTTPClient.swift
//  UnsplashFeed
//
//  Created by Christophe Bugnon on 07/11/2023.
//

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct UnexpectedValuesRepresentation: Error {}
    
    public func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Client-ID GxTa3h-v4ci58nxl4fVT4JpHEruTIwnO8iJeCibjr2E",
                         forHTTPHeaderField: "Authorization")
        
        session.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
            } else if let data, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}
