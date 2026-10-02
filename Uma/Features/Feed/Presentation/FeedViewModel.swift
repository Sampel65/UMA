//
//  FeedViewModel.swift
//  Uma
//

import Foundation
import Observation

@Observable
final class FeedViewModel {
    enum State: Equatable {
        case loading
        case loaded
        case empty
        case offline
        case failed(message: String)
    }

    enum PaginationState: Equatable {
        case idle
        case loading
        case failed
        case exhausted
    }

    private(set) var state: State = .loading
    private(set) var posts: [Post] = []
    private(set) var paginationState: PaginationState = .idle
    private(set) var isShowingCachedContent = false
    private(set) var alertMessage = ""
    var isShowingAlert = false

    @ObservationIgnored private let repository: any FeedRepository
    @ObservationIgnored private var nextPage = 1
    @ObservationIgnored private var pendingLikeIDs: Set<Post.ID> = []
    /// Incremented whenever a refresh replaces the feed, so in-flight pages for the old feed are discarded.
    @ObservationIgnored private var generation = 0

    init(repository: any FeedRepository) {
        self.repository = repository
    }

    /// Loads the first page when nothing is on screen; also used by the retry actions.
    func loadInitialPage() async {
        guard posts.isEmpty else { return }
        state = .loading
        await refresh()
    }

    func refresh() async {
        do {
            let page = try await repository.loadPage(1)
            generation += 1
            posts = page.posts
            nextPage = 2
            isShowingCachedContent = page.isFromCache
            paginationState = page.hasMore ? .idle : .exhausted
            state = posts.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            // The initiating view went away; keep whatever is currently on screen.
        } catch {
            if posts.isEmpty {
                state = error as? FeedError == .offline ? .offline : .failed(message: error.localizedDescription)
            } else {
                showAlert(error.localizedDescription)
            }
        }
    }

    func loadNextPage() async {
        guard state == .loaded, paginationState == .idle || paginationState == .failed else { return }
        let requestGeneration = generation
        paginationState = .loading
        do {
            let page = try await repository.loadPage(nextPage)
            guard requestGeneration == generation else { return }
            let loadedIDs = Set(posts.map(\.id))
            posts.append(contentsOf: page.posts.filter { !loadedIDs.contains($0.id) })
            nextPage += 1
            paginationState = page.hasMore ? .idle : .exhausted
        } catch {
            guard requestGeneration == generation else { return }
            paginationState = error is CancellationError ? .idle : .failed
        }
    }

    func post(withID id: Post.ID) -> Post? {
        posts.first { $0.id == id }
    }

    func posts(by author: Author) -> [Post] {
        posts.filter { $0.author.id == author.id }
    }

    func handleConnectivityRestored() async {
        guard isShowingCachedContent || state == .offline else { return }
        await refresh()
    }

    /// Applies the like immediately and rolls it back if the request fails.
    func toggleLike(for postID: Post.ID) async {
        guard !pendingLikeIDs.contains(postID), let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        pendingLikeIDs.insert(postID)
        defer { pendingLikeIDs.remove(postID) }

        let isLiked = !posts[index].isLiked
        posts[index].setLiked(isLiked)
        do {
            try await repository.setLike(isLiked, for: postID)
        } catch {
            if let index = posts.firstIndex(where: { $0.id == postID }) {
                posts[index].setLiked(!isLiked)
            }
            showAlert(error.localizedDescription)
        }
    }

    private func showAlert(_ message: String) {
        alertMessage = message
        isShowingAlert = true
    }
}
