//
//  MockAPIURLProtocol.swift
//  Uma
//

import Foundation
import Network
import os

/// Intercepts requests to `MockAPIURLProtocol.baseURL` and answers them from `MockAPIServer`,

nonisolated final class MockAPIURLProtocol: URLProtocol {
    static let baseURL = URL(string: "https://api.uma.social")!

    private var pendingResponse: DispatchWorkItem?

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == baseURL.host
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let server = MockAPIServer.shared
        let reachability = Reachability.shared
        let request = request
        let urlProtocol = UncheckedSendable(value: self)
        let workItem = DispatchWorkItem {
            let result = Self.result(for: request, from: server, isOnline: reachability.isOnline)
            urlProtocol.value.deliver(result)
        }
        pendingResponse = workItem
        DispatchQueue.global().asyncAfter(deadline: .now() + server.configuration.latency, execute: workItem)
    }

    /// Called by the loading system after every request, finished or cancelled. Releasing the work item
    /// here breaks the `self → pendingResponse → block → self` cycle.
    override func stopLoading() {
        pendingResponse?.cancel()
        pendingResponse = nil
    }

    private func deliver(_ result: Result<(HTTPURLResponse, Data), URLError>) {
        switch result {
        case .success(let (response, body)):
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    private static func result(
        for request: URLRequest,
        from server: MockAPIServer,
        isOnline: Bool
    ) -> Result<(HTTPURLResponse, Data), URLError> {
        guard isOnline else { return .failure(URLError(.notConnectedToInternet)) }

        let (statusCode, body) = server.response(for: request)
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1",
                                             headerFields: ["Content-Type": "application/json"]) else {
            return .failure(URLError(.badServerResponse))
        }
        return .success((response, body))
    }
}

/// Mirrors the device's connectivity so the mock fails exactly when a real request would.
private nonisolated final class Reachability: Sendable {
    static let shared = Reachability()

    private let monitor = NWPathMonitor()
    private let isSatisfied = OSAllocatedUnfairLock(initialState: true)

    var isOnline: Bool {
        isSatisfied.withLock { $0 }
    }

    private init() {
        monitor.pathUpdateHandler = { [isSatisfied] path in
            isSatisfied.withLock { $0 = path.status == .satisfied }
        }
        monitor.start(queue: DispatchQueue(label: "MockAPI.Reachability"))
    }
}

/// URLProtocol isn't Sendable, but the loading system keeps the instance alive until it finishes
/// and serialises `startLoading`/`stopLoading`, so handing it to the delayed work item is safe.
private nonisolated struct UncheckedSendable<Value>: @unchecked Sendable {
    let value: Value
}

extension URLSession {
    /// A session whose requests to the mock host are served by `MockAPIServer`.
    static let mockAPI: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockAPIURLProtocol.self]
        return URLSession(configuration: configuration)
    }()
}
