//
//  FeedDTOs.swift
//  Uma
//

import Foundation

/// `GET /v1/posts` response envelope.
nonisolated struct FeedResponseDTO: Codable, Sendable {
    let data: [PostDTO]
    let page: Int
    let hasMore: Bool
}

nonisolated struct PostDTO: Codable, Equatable, Sendable {
    let id: String
    let author: AuthorDTO
    let text: String
    let mediaUrl: URL?
    let location: String?
    let createdAt: Date
    var likeCount: Int
    let commentCount: Int
    var isLiked: Bool
}

nonisolated struct AuthorDTO: Codable, Equatable, Sendable {
    let id: String
    let name: String
    let avatarUrl: URL
}

extension Post {
    init(_ dto: PostDTO) {
        self.init(
            id: dto.id,
            author: Author(id: dto.author.id, name: dto.author.name, avatarURL: dto.author.avatarUrl),
            text: dto.text,
            mediaURL: dto.mediaUrl,
            location: dto.location,
            createdAt: dto.createdAt,
            likeCount: dto.likeCount,
            commentCount: dto.commentCount,
            isLiked: dto.isLiked
        )
    }
}
