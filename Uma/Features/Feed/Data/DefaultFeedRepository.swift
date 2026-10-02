//
//  DefaultFeedRepository.swift
//  Uma
//

/// Network-first repository that mirrors loaded pages to the cache
/// and falls back to it when the first page can't be fetched.
final class DefaultFeedRepository: FeedRepository {
    private let service: any FeedService
    private let cache: any FeedCache
    private let pageSize: Int
    private var pages: [Int: [Post]] = [:]

    init(service: any FeedService, cache: any FeedCache, pageSize: Int = 10) {
        self.service = service
        self.cache = cache
        self.pageSize = pageSize
    }

    func loadPage(_ page: Int) async throws -> FeedPage {
        do {
            let remotePage = try await service.fetchPosts(page: page, pageSize: pageSize)
            if page == 1 { pages.removeAll() }
            pages[page] = remotePage.posts
            await cache.save(contiguousPosts)
            return remotePage
        } catch let error where page == 1 && !(error is CancellationError) {
            let cachedPosts = await cache.load()
            guard !cachedPosts.isEmpty else { throw error }
            pages = [1: cachedPosts]
            return FeedPage(posts: cachedPosts, hasMore: false, isFromCache: true)
        }
    }

    func setLike(_ isLiked: Bool, for postID: Post.ID) async throws {
        try await service.setLike(isLiked, postID: postID)
        guard let (page, index) = location(of: postID) else { return }
        pages[page]?[index].setLiked(isLiked)
        await cache.save(contiguousPosts)
    }

    /// Posts from page 1 up to the first missing page, so a page that lands after a refresh
    /// can never leave a gap or reorder the cached feed.
    private var contiguousPosts: [Post] {
        var posts: [Post] = []
        var page = 1
        while let pagePosts = pages[page] {
            posts += pagePosts
            page += 1
        }
        return posts
    }

    private func location(of postID: Post.ID) -> (page: Int, index: Int)? {
        for (page, posts) in pages {
            if let index = posts.firstIndex(where: { $0.id == postID }) { return (page, index) }
        }
        return nil
    }
}
