//
//  FeedDTOTests.swift
//  UmaTests
//

import Foundation
import Testing
@testable import Uma

struct FeedDTOTests {
    @Test func decodesSnakeCaseResponseIntoDomainPosts() throws {
        let json = Data("""
        {
          "data": [{
            "id": "post-1",
            "author": { "id": "user-1", "name": "Amara Okafor", "avatar_url": "https://example.com/a.jpg" },
            "text": "Hello",
            "media_url": null,
            "location": "Lagos, Nigeria",
            "created_at": "2026-10-02T12:00:00Z",
            "like_count": 7,
            "comment_count": 2,
            "is_liked": true
          }],
          "page": 1,
          "has_more": false
        }
        """.utf8)

        let response = try JSONDecoder.api.decode(FeedResponseDTO.self, from: json)
        let post = try #require(response.data.map(Post.init).first)

        #expect(!response.hasMore)
        #expect(post.author.name == "Amara Okafor")
        #expect(post.mediaURL == nil)
        #expect(post.likeCount == 7 && post.isLiked)
        #expect(post.createdAt == Date(timeIntervalSince1970: 1_790_942_400))
    }
}
