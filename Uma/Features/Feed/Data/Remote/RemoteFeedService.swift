//
//  RemoteFeedService.swift
//  Uma
//

import Foundation

final class RemoteFeedService: FeedService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchPosts(page: Int, pageSize: Int) async throws -> FeedPage {
        try await mapErrors {
            let response: FeedResponseDTO = try await client.send(.posts(page: page, limit: pageSize))
            return FeedPage(posts: response.data.map(Post.init), hasMore: response.hasMore)
        }
    }

    func setLike(_ isLiked: Bool, postID: Post.ID) async throws {
        try await mapErrors {
            try await client.send(.like(postID: postID, isLiked: isLiked))
        }
    }

    /// Translates transport errors into the domain errors the presentation layer understands.
    private func mapErrors<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch is CancellationError {
            throw CancellationError()
        } catch APIError.offline {
            throw FeedError.offline
        } catch {
            throw FeedError.server
        }
    }
}

private extension Endpoint {
    static func posts(page: Int, limit: Int) -> Endpoint {
        Endpoint(path: "v1/posts", queryItems: [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
        ])
    }

    static func like(postID: Post.ID, isLiked: Bool) -> Endpoint {
        Endpoint(path: "v1/posts/\(postID)/like", method: isLiked ? .post : .delete)
    }
}
