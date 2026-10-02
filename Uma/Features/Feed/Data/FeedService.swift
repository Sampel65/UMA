//
//  FeedService.swift
//  Uma
//

/// Remote API boundary, implemented over HTTP by `RemoteFeedService`.
protocol FeedService {
    func fetchPosts(page: Int, pageSize: Int) async throws -> FeedPage
    func setLike(_ isLiked: Bool, postID: Post.ID) async throws
}
