//
//  DefaultFeedRepositoryTests.swift
//  UmaTests
//

import Testing
@testable import Uma

struct DefaultFeedRepositoryTests {
    private let service = StubFeedService()

    @Test func successfulLoadIsWrittenToCache() async throws {
        let cache = InMemoryFeedCache()
        service.result = .success(FeedPage(posts: [.fixture(id: "1")], hasMore: false))
        let repository = DefaultFeedRepository(service: service, cache: cache)

        let page = try await repository.loadPage(1)

        #expect(!page.isFromCache)
        #expect(await cache.posts.map(\.id) == ["1"])
    }

    @Test func failedFirstPageFallsBackToCache() async throws {
        let cache = InMemoryFeedCache(posts: [.fixture(id: "cached")])
        service.result = .failure(FeedError.offline)
        let repository = DefaultFeedRepository(service: service, cache: cache)

        let page = try await repository.loadPage(1)

        #expect(page.isFromCache)
        #expect(!page.hasMore)
        #expect(page.posts.map(\.id) == ["cached"])
    }

    @Test func failedFirstPageWithEmptyCacheRethrows() async {
        service.result = .failure(FeedError.offline)
        let repository = DefaultFeedRepository(service: service, cache: InMemoryFeedCache())

        await #expect(throws: FeedError.offline) {
            try await repository.loadPage(1)
        }
    }

    @Test func failedLaterPageDoesNotFallBackToCache() async {
        service.result = .failure(FeedError.server)
        let repository = DefaultFeedRepository(service: service, cache: InMemoryFeedCache(posts: [.fixture()]))

        await #expect(throws: FeedError.server) {
            try await repository.loadPage(2)
        }
    }

    @Test func cacheOnlyContainsContiguousPages() async throws {
        let cache = InMemoryFeedCache()
        service.resultsByPage[1] = .success(FeedPage(posts: [.fixture(id: "p1")], hasMore: true))
        service.resultsByPage[3] = .success(FeedPage(posts: [.fixture(id: "p3")], hasMore: false))
        let repository = DefaultFeedRepository(service: service, cache: cache)

        _ = try await repository.loadPage(1)
        _ = try await repository.loadPage(3)

        #expect(await cache.posts.map(\.id) == ["p1"])
    }

    @Test func likeIsPersistedToCache() async throws {
        let cache = InMemoryFeedCache()
        service.result = .success(FeedPage(posts: [.fixture(id: "1", likeCount: 5)], hasMore: false))
        let repository = DefaultFeedRepository(service: service, cache: cache)
        _ = try await repository.loadPage(1)

        try await repository.setLike(true, for: "1")

        let cachedPost = try #require(await cache.posts.first)
        #expect(cachedPost.isLiked)
        #expect(cachedPost.likeCount == 6)
    }
}
