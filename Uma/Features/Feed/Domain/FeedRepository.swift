//
//  FeedRepository.swift
//  Uma
//

/// Single source of truth for feed data consumed by the presentation layer.
protocol FeedRepository {
    /// Loads a 1-based page. When the first page can't be fetched, implementations
    /// may return cached posts with `isFromCache` set instead of throwing.
    func loadPage(_ page: Int) async throws -> FeedPage
    func setLike(_ isLiked: Bool, for postID: Post.ID) async throws
}
