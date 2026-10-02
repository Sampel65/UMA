//
//  APIClient.swift
//  Uma
//

import Foundation

nonisolated enum APIError: Error, Equatable {
    case offline
    case invalidRequest
    case invalidResponse
    case httpStatus(Int)
    case decoding
}

/// Thin URLSession wrapper: builds requests, validates status codes and decodes JSON.
final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: URL, session: URLSession = .shared, decoder: JSONDecoder = .api) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    func send<Response: Decodable>(_ endpoint: Endpoint) async throws -> Response {
        let data = try await data(for: endpoint)
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    func send(_ endpoint: Endpoint) async throws {
        _ = try await data(for: endpoint)
    }

    private func data(for endpoint: Endpoint) async throws -> Data {
        var components = URLComponents(url: baseURL.appending(path: endpoint.path), resolvingAgainstBaseURL: false)
        components?.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems
        guard let url = components?.url else { throw APIError.invalidRequest }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw Self.map(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(httpResponse.statusCode) else { throw APIError.httpStatus(httpResponse.statusCode) }
        return data
    }

    private static func map(_ error: URLError) -> any Error {
        switch error.code {
        case .cancelled:
            CancellationError()
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            APIError.offline
        default:
            error
        }
    }
}
