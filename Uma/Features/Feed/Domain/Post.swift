//
//  Post.swift
//  Uma
//

import Foundation

nonisolated struct Author: Hashable, Codable, Sendable {
    let id: String
    let name: String
    let avatarURL: URL
}

nonisolated struct Post: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let author: Author
    let text: String
    let mediaURL: URL?
    let location: String?
    let createdAt: Date
    private(set) var likeCount: Int
    let commentCount: Int
    private(set) var isLiked: Bool

    mutating func setLiked(_ liked: Bool) {
        guard liked != isLiked else { return }
        isLiked = liked
        likeCount = max(0, likeCount + (liked ? 1 : -1))
    }
}
