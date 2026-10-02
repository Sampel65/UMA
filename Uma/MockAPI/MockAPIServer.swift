//
//  MockAPIServer.swift
//  Uma
//

import Foundation
import os

/// In-process stand-in for the Uma backend, seeded from the bundled `posts.json`.
///
/// Routes:
/// - `GET /v1/posts?page=<n>&limit=<n>` → `200` with a `FeedResponseDTO`
/// - `POST /v1/posts/<id>/like` and `DELETE /v1/posts/<id>/like` → `204`
nonisolated final class MockAPIServer: Sendable {
    struct Configuration: Sendable {
        var latency: DispatchTimeInterval = .milliseconds(800)
        var failureRate = 0.0
        var isEmpty = false

        /// Reads the `-mockFailureRate <0...1>` and `-mockEmptyFeed YES` launch arguments.
        static var launchArguments: Self {
            let defaults = UserDefaults.standard
            return Self(failureRate: defaults.double(forKey: "mockFailureRate"), isEmpty: defaults.bool(forKey: "mockEmptyFeed"))
        }
    }

    static let shared = MockAPIServer(configuration: .launchArguments)

    let configuration: Configuration
    private let posts: OSAllocatedUnfairLock<[PostDTO]>

    init(configuration: Configuration = .init(), posts: [PostDTO] = MockAPIServer.bundledPosts()) {
        self.configuration = configuration
        self.posts = OSAllocatedUnfairLock(initialState: configuration.isEmpty ? [] : posts)
    }

    func response(for request: URLRequest) -> (statusCode: Int, body: Data) {
        guard Double.random(in: 0..<1) >= configuration.failureRate else { return (500, Data()) }
        guard let url = request.url else { return (400, Data()) }

        let method = request.httpMethod ?? "GET"
        let segments = url.pathComponents.filter { $0 != "/" }

        if method == "GET", segments == ["v1", "posts"] {
            return listPosts(url)
        }
        if segments.count == 4, segments[0] == "v1", segments[1] == "posts", segments[3] == "like",
           method == "POST" || method == "DELETE" {
            return setLike(method == "POST", postID: segments[2])
        }
        return (404, Data())
    }

    static func bundledPosts() -> [PostDTO] {
        guard let url = Bundle.main.url(forResource: "posts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let posts = try? JSONDecoder.api.decode([PostDTO].self, from: data) else {
            assertionFailure("MockAPI/posts.json is missing or malformed.")
            return []
        }
        return posts
    }

    private func listPosts(_ url: URL) -> (statusCode: Int, body: Data) {
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func intValue(_ name: String) -> Int? {
            queryItems.first { $0.name == name }?.value.flatMap(Int.init)
        }
        let page = intValue("page") ?? 1
        let limit = intValue("limit") ?? 10
        guard page >= 1, (1...50).contains(limit) else { return (400, Data()) }

        let allPosts = posts.withLock { $0 }
        let start = min((page - 1) * limit, allPosts.count)
        let end = min(start + limit, allPosts.count)
        let body = FeedResponseDTO(data: Array(allPosts[start..<end]), page: page, hasMore: end < allPosts.count)
        guard let data = try? JSONEncoder.api.encode(body) else { return (500, Data()) }
        return (200, data)
    }

    private func setLike(_ isLiked: Bool, postID: String) -> (statusCode: Int, body: Data) {
        let found = posts.withLock { posts in
            guard let index = posts.firstIndex(where: { $0.id == postID }) else { return false }
            if posts[index].isLiked != isLiked {
                posts[index].isLiked = isLiked
                posts[index].likeCount += isLiked ? 1 : -1
            }
            return true
        }
        return (found ? 204 : 404, Data())
    }
}
