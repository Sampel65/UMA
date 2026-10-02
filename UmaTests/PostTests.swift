//
//  PostTests.swift
//  UmaTests
//

import Foundation
import Testing
@testable import Uma

struct PostTests {
    @Test func likingAndUnlikingAdjustsCount() {
        var post = Post.fixture(likeCount: 10)

        post.setLiked(true)
        #expect(post.isLiked && post.likeCount == 11)

        post.setLiked(false)
        #expect(!post.isLiked && post.likeCount == 10)
    }

    @Test func settingSameLikeStateIsIdempotent() {
        var post = Post.fixture(likeCount: 10, isLiked: true)

        post.setLiked(true)

        #expect(post.likeCount == 10)
    }

    @Test func postsRoundTripThroughJSON() throws {
        let post = Post.fixture(id: "1", isLiked: true)

        let data = try JSONEncoder().encode([post])
        let decoded = try JSONDecoder().decode([Post].self, from: data)

        #expect(decoded == [post])
    }
}
