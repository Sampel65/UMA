//
//  MockAPIServerTests.swift
//  UmaTests
//

import Foundation
import Testing
@testable import Uma

struct MockAPIServerTests {
    private let server = MockAPIServer(posts: MockAPIServer.bundledPosts())

    @Test func bundledFixtureDecodes() {
        #expect(MockAPIServer.bundledPosts().count == 42)
    }

    @Test func paginatesPostsAndReportsHasMore() throws {
        let firstPage = try decodePage(page: 1, limit: 20)
        let lastPage = try decodePage(page: 3, limit: 20)

        #expect(firstPage.data.count == 20)
        #expect(firstPage.hasMore)
        #expect(lastPage.data.count == 2)
        #expect(!lastPage.hasMore)
    }

    @Test func rejectsInvalidPagination() {
        #expect(server.response(for: request("v1/posts?page=0&limit=10")).statusCode == 400)
        #expect(server.response(for: request("v1/posts?page=1&limit=500")).statusCode == 400)
    }

    @Test func likeEndpointUpdatesServerState() throws {
        let postID = try #require(MockAPIServer.bundledPosts().first?.id)

        #expect(server.response(for: request("v1/posts/\(postID)/like", method: "POST")).statusCode == 204)

        let post = try #require(try decodePage(page: 1, limit: 1).data.first)
        #expect(post.isLiked)
        #expect(server.response(for: request("v1/posts/missing/like", method: "POST")).statusCode == 404)
    }

    private func request(_ path: String, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.uma.social/\(path)")!)
        request.httpMethod = method
        return request
    }

    private func decodePage(page: Int, limit: Int) throws -> FeedResponseDTO {
        let response = server.response(for: request("v1/posts?page=\(page)&limit=\(limit)"))
        try #require(response.statusCode == 200)
        return try JSONDecoder.api.decode(FeedResponseDTO.self, from: response.body)
    }
}
