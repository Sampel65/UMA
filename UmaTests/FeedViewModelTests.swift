//
//  FeedViewModelTests.swift
//  UmaTests
//

import Foundation
import Testing
@testable import Uma

struct FeedViewModelTests {
    private let repository = StubFeedRepository()

    @Test func loadingFirstPageShowsPosts() async {
        repository.pages[1] = .success(FeedPage(posts: [.fixture(), .fixture()], hasMore: true))
        let viewModel = FeedViewModel(repository: repository)

        await viewModel.loadInitialPage()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.posts.count == 2)
        #expect(viewModel.paginationState == .idle)
    }

    @Test func emptyFeedShowsEmptyState() async {
        let viewModel = FeedViewModel(repository: repository)

        await viewModel.loadInitialPage()

        #expect(viewModel.state == .empty)
    }

    @Test func offlineWithoutCacheShowsOfflineState() async {
        repository.pages[1] = .failure(FeedError.offline)
        let viewModel = FeedViewModel(repository: repository)

        await viewModel.loadInitialPage()

        #expect(viewModel.state == .offline)
    }

    @Test func serverErrorShowsErrorState() async {
        repository.pages[1] = .failure(FeedError.server)
        let viewModel = FeedViewModel(repository: repository)

        await viewModel.loadInitialPage()

        #expect(viewModel.state == .failed(message: FeedError.server.localizedDescription))
    }

    @Test func paginationAppendsPagesUntilExhausted() async {
        repository.pages[1] = .success(FeedPage(posts: [.fixture()], hasMore: true))
        repository.pages[2] = .success(FeedPage(posts: [.fixture()], hasMore: false))
        let viewModel = FeedViewModel(repository: repository)

        await viewModel.loadInitialPage()
        await viewModel.loadNextPage()
        await viewModel.loadNextPage()

        #expect(viewModel.posts.count == 2)
        #expect(viewModel.paginationState == .exhausted)
    }

    @Test func failedPaginationCanBeRetried() async {
        repository.pages[1] = .success(FeedPage(posts: [.fixture()], hasMore: true))
        repository.pages[2] = .failure(FeedError.server)
        let viewModel = FeedViewModel(repository: repository)

        await viewModel.loadInitialPage()
        await viewModel.loadNextPage()
        #expect(viewModel.paginationState == .failed)

        repository.pages[2] = .success(FeedPage(posts: [.fixture()], hasMore: false))
        await viewModel.loadNextPage()
        #expect(viewModel.posts.count == 2)
    }

    @Test func refreshDuringPaginationDiscardsStalePage() async {
        repository.pages[1] = .success(FeedPage(posts: [.fixture(id: "old")], hasMore: true))
        repository.pages[2] = .success(FeedPage(posts: [.fixture(id: "stale")], hasMore: false))
        let viewModel = FeedViewModel(repository: repository)
        await viewModel.loadInitialPage()

        repository.beforeResponse = { [repository] _ in
            repository.pages[1] = .success(FeedPage(posts: [.fixture(id: "fresh")], hasMore: true))
            await viewModel.refresh()
        }
        await viewModel.loadNextPage()

        #expect(viewModel.posts.map(\.id) == ["fresh"])
        #expect(viewModel.paginationState == .idle)
    }

    @Test func paginationSkipsPostsAlreadyInFeed() async {
        repository.pages[1] = .success(FeedPage(posts: [.fixture(id: "1")], hasMore: true))
        repository.pages[2] = .success(FeedPage(posts: [.fixture(id: "1"), .fixture(id: "2")], hasMore: false))
        let viewModel = FeedViewModel(repository: repository)

        await viewModel.loadInitialPage()
        await viewModel.loadNextPage()

        #expect(viewModel.posts.map(\.id) == ["1", "2"])
    }

    @Test func lookupsResolveNavigationDestinations() async {
        let author = Author.fixture(id: "me")
        repository.pages[1] = .success(FeedPage(posts: [.fixture(id: "mine", author: author), .fixture(id: "other")], hasMore: false))
        let viewModel = FeedViewModel(repository: repository)
        await viewModel.loadInitialPage()

        #expect(viewModel.post(withID: "other")?.id == "other")
        #expect(viewModel.post(withID: "missing") == nil)
        #expect(viewModel.posts(by: author).map(\.id) == ["mine"])
    }

    @Test func likingUpdatesPostOptimistically() async {
        repository.pages[1] = .success(FeedPage(posts: [.fixture(id: "1", likeCount: 10)], hasMore: false))
        let viewModel = FeedViewModel(repository: repository)
        await viewModel.loadInitialPage()

        await viewModel.toggleLike(for: "1")

        #expect(viewModel.posts[0].isLiked)
        #expect(viewModel.posts[0].likeCount == 11)
    }

    @Test func failedLikeIsRolledBack() async {
        repository.pages[1] = .success(FeedPage(posts: [.fixture(id: "1", likeCount: 10)], hasMore: false))
        repository.likeError = FeedError.offline
        let viewModel = FeedViewModel(repository: repository)
        await viewModel.loadInitialPage()

        await viewModel.toggleLike(for: "1")

        #expect(!viewModel.posts[0].isLiked)
        #expect(viewModel.posts[0].likeCount == 10)
        #expect(viewModel.isShowingAlert)
    }
}
