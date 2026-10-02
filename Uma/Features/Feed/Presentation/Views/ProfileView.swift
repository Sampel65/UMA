//
//  ProfileView.swift
//  Uma
//

import SwiftUI

struct ProfileView: View {
    let author: Author
    let viewModel: FeedViewModel
    @Environment(Router.self) private var router

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        let posts = viewModel.posts(by: author)

        ScrollView {
            VStack(spacing: 20) {
                header(postCount: posts.count)

                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(posts) { post in
                        Button { router.push(.post(id: post.id)) } label: {
                            tile(for: post)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Post: \(post.text)")
                        .scrollEntranceEffect()
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(author.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func header(postCount: Int) -> some View {
        VStack(spacing: 10) {
            RemoteImage(url: author.avatarURL)
                .frame(width: 88, height: 88)
                .clipShape(.circle)
                .accessibilityHidden(true)

            Text(author.name)
                .font(.headline)

            Text("^[\(postCount) post](inflect: true)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func tile(for post: Post) -> some View {
        if let mediaURL = post.mediaURL {
            RemoteImage(url: mediaURL)
                .aspectRatio(1, contentMode: .fit)
        } else {
            Rectangle()
                .fill(.quaternary)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Text(post.text)
                        .font(.caption)
                        .lineLimit(5)
                        .padding(8)
                }
        }
    }
}
