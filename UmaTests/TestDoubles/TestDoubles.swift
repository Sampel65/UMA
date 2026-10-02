//
//  TestDoubles.swift
//  UmaTests
//

import Foundation
@testable import Uma

extension Post {
    static func fixture(
        id: String = UUID().uuidString,
        author: Author = .fixture(),
        likeCount: Int = 10,
        isLiked: Bool = false
    ) -> Post {
        Post(
            id: id,
            author: author,
            text: "Hello, Uma!",
            mediaURL: nil,
            location: "Lagos, Nigeria",
            createdAt: Date(timeIntervalSince1970: 0),
            likeCount: likeCount,
            commentCount: 2,
            isLiked: isLiked
        )
    }
}

extension Author {
    static func fixture(id: String = "author") -> Author {
        Author(id: id, name: "Test User", avatarURL: URL(string: "https://example.com/\(id).jpg")!)
    }
}

final class StubFeedRepository: FeedRepository {
    var pages: [Int: Result<FeedPage, any Error>] = [:]
    var likeError: (any Error)?
    /// Runs once while a page request is in flight, then clears itself.
    var beforeResponse: ((Int) async -> Void)?

    func loadPage(_ page: Int) async throws -> FeedPage {
        let result = pages[page] ?? .success(FeedPage(posts: [], hasMore: false))
        if let hook = beforeResponse {
            beforeResponse = nil
            await hook(page)
        }
        return try result.get()
    }

    func setLike(_ isLiked: Bool, for postID: Post.ID) async throws {
        if let likeError { throw likeError }
    }
}

final class StubFeedService: FeedService {
    var result: Result<FeedPage, any Error> = .success(FeedPage(posts: [], hasMore: false))
    var resultsByPage: [Int: Result<FeedPage, any Error>] = [:]

    func fetchPosts(page: Int, pageSize: Int) async throws -> FeedPage {
        try (resultsByPage[page] ?? result).get()
    }

    func setLike(_ isLiked: Bool, postID: Post.ID) async throws {}
}

actor InMemoryFeedCache: FeedCache {
    private(set) var posts: [Post]

    init(posts: [Post] = []) {
        self.posts = posts
    }

    func load() -> [Post] { posts }
    func save(_ posts: [Post]) { self.posts = posts }
}
