//
//  Endpoint.swift
//  Uma
//

import Foundation

nonisolated struct Endpoint: Sendable {
    enum Method: String, Sendable {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
    }

    var path: String
    var method: Method = .get
    var queryItems: [URLQueryItem] = []
}
