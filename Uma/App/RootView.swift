//
//  RootView.swift
//  Uma
//

import SwiftUI

/// Hosts the splash screen and the app's single navigation stack, mapping each `Route` to its screen.
struct RootView: View {
    @Bindable var feedViewModel: FeedViewModel

    @State private var router = Router()
    @State private var isShowingSplash = true

    private static let splashDuration: Duration = .seconds(1.4)

    var body: some View {
        ZStack {
            NavigationStack(path: $router.path) {
                FeedView(viewModel: feedViewModel)
                    .navigationDestination(for: Route.self, destination: destination)
            }
            .environment(router)
            .accessibilityHidden(isShowingSplash)
            .alert("Something Went Wrong", isPresented: $feedViewModel.isShowingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(feedViewModel.alertMessage)
            }

            if isShowingSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(for: Self.splashDuration)
            withAnimation(.easeOut(duration: 0.35)) { isShowingSplash = false }
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .profile(let author):
            ProfileView(author: author, viewModel: feedViewModel)
        case .post(let id):
            PostDetailView(postID: id, viewModel: feedViewModel)
        }
    }
}
