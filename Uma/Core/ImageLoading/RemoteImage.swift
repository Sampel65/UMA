//
//  RemoteImage.swift
//  Uma
//

import SwiftUI

/// Fills its frame with a cached remote image, showing a placeholder while loading or on failure.
struct RemoteImage: View {
    let url: URL?

    @Environment(\.imageLoader) private var imageLoader
    @State private var image: UIImage?
    @State private var loadedURL: URL?
    @State private var didFail = false

    var body: some View {
        Rectangle()
            .fill(.quaternary)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                } else if didFail {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            }
            .clipped()
            .task(id: url) { await load() }
    }

    /// `.task` re-runs every time the view reappears; only fetch when the URL isn't already displayed.
    private func load() async {
        guard url != loadedURL || image == nil else { return }
        image = nil
        loadedURL = nil
        didFail = false
        guard let url else { return }
        do {
            let loaded = try await imageLoader.image(for: url)
            loadedURL = url
            withAnimation(.easeIn(duration: 0.2)) { image = loaded }
        } catch {
            didFail = !(error is CancellationError)
        }
    }
}

extension EnvironmentValues {
    @Entry var imageLoader: ImageLoader = .shared
}
