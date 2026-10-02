//
//  PostDetailView.swift
//  Uma
//

import SwiftUI

struct PostDetailView: View {
    let postID: Post.ID
    let viewModel: FeedViewModel
    @Environment(Router.self) private var router

    var body: some View {
        Group {
            if let post = viewModel.post(withID: postID) {
                ScrollView {
                    PostCardView(
                        post: post,
                        onLike: { Task { await viewModel.toggleLike(for: post.id) } },
                        onAuthorTap: { router.push(.profile(post.author)) }
                    )
                    .padding(.vertical)
                }
            } else {
                ContentUnavailableView(
                    "Post Unavailable",
                    systemImage: "photo",
                    description: Text("This post is no longer available.")
                )
            }
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
    }
}
