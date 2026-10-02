//
//  FeedPage.swift
//  Uma
//

nonisolated struct FeedPage: Sendable {
    let posts: [Post]
    let hasMore: Bool
    var isFromCache = false
}
