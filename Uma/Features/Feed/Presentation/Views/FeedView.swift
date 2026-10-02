//
//  FeedView.swift
//  Uma
//

import SwiftUI

struct FeedView: View {
    let viewModel: FeedViewModel
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Environment(Router.self) private var router

    private var isShowingOfflineBanner: Bool {
        viewModel.isShowingCachedContent || !networkMonitor.isConnected
    }

    var body: some View {
        content
            .animation(.smooth, value: viewModel.state)
            .navigationTitle("Uma")
            .task { await viewModel.loadInitialPage() }
            .onChange(of: networkMonitor.isConnected) { _, isConnected in
                guard isConnected else { return }
                Task { await viewModel.handleConnectivityRestored() }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded:
            feed
        case .empty:
            stateView("No Posts Yet", systemImage: "photo.on.rectangle.angled", message: "When people share posts, they'll appear here.")
        case .offline:
            stateView("You're Offline", systemImage: "wifi.slash", message: "Connect to the internet to see the latest posts.")
        case .failed(let message):
            stateView("Couldn't Load Feed", systemImage: "exclamationmark.triangle", message: message)
        }
    }

    private var feed: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(viewModel.posts) { post in
                    PostCardView(
                        post: post,
                        onLike: { Task { await viewModel.toggleLike(for: post.id) } },
                        onAuthorTap: { router.push(.profile(post.author)) }
                    )
                    .scrollEntranceEffect()
                }
                paginationFooter
            }
            .padding(.vertical)
        }
        .refreshable { await viewModel.refresh() }
        .safeAreaInset(edge: .top) {
            if isShowingOfflineBanner {
                OfflineBanner(isConnected: networkMonitor.isConnected)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: isShowingOfflineBanner)
    }

    @ViewBuilder
    private var paginationFooter: some View {
        switch viewModel.paginationState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding()
                .task(id: viewModel.posts.count) { await viewModel.loadNextPage() }
        case .failed:
            Button("Couldn't load more posts. Tap to retry.", systemImage: "arrow.clockwise") {
                Task { await viewModel.loadNextPage() }
            }
            .font(.footnote)
            .padding()
        case .exhausted:
            EmptyView()
        }
    }

    private func stateView(_ title: LocalizedStringKey, systemImage: String, message: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task { await viewModel.loadInitialPage() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct OfflineBanner: View {
    let isConnected: Bool

    var body: some View {
        Label(isConnected ? "Showing saved posts" : "You're offline", systemImage: "wifi.slash")
            .font(.footnote.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: .capsule)
            .padding(.top, 4)
    }
}

#Preview {
    let client = APIClient(baseURL: MockAPIURLProtocol.baseURL, session: .mockAPI)
    let repository = DefaultFeedRepository(service: RemoteFeedService(client: client), cache: FileFeedCache())
    NavigationStack {
        FeedView(viewModel: FeedViewModel(repository: repository))
    }
    .environment(NetworkMonitor())
    .environment(Router())
}
