//
//  UmaApp.swift
//  Uma
//

import SwiftUI

@main
struct UmaApp: App {
    @State private var networkMonitor: NetworkMonitor
    @State private var feedViewModel: FeedViewModel

    init() {
        let client = APIClient(baseURL: MockAPIURLProtocol.baseURL, session: .mockAPI)
        let repository = DefaultFeedRepository(service: RemoteFeedService(client: client), cache: FileFeedCache())

        _networkMonitor = State(initialValue: NetworkMonitor())
        _feedViewModel = State(initialValue: FeedViewModel(repository: repository))
    }

    var body: some Scene {
        WindowGroup {
            RootView(feedViewModel: feedViewModel)
                .environment(networkMonitor)
        }
    }
}
