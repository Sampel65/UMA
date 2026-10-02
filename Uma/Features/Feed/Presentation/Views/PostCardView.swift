//
//  PostCardView.swift
//  Uma
//

import SwiftUI

struct PostCardView: View {
    let post: Post
    let onLike: () -> Void
    let onAuthorTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onAuthorTap) { header }
                .buttonStyle(.plain)
                .accessibilityHint("Opens \(post.author.name)'s profile")
                .padding(.horizontal)

            if let mediaURL = post.mediaURL {
                RemoteImage(url: mediaURL)
                    .aspectRatio(1, contentMode: .fit)
                    .onTapGesture(count: 2) {
                        if !post.isLiked { onLike() }
                    }
                    .accessibilityLabel("Photo shared by \(post.author.name)")
                    .accessibilityAddTraits(.isImage)
            }

            VStack(alignment: .leading, spacing: 6) {
                actions
                Text("\(Text(post.author.name).fontWeight(.semibold)) \(post.text)")
                Text(post.createdAt, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        HStack(spacing: 10) {
            RemoteImage(url: post.author.avatarURL)
                .frame(width: 36, height: 36)
                .clipShape(.circle)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(post.author.name)
                    .font(.subheadline.weight(.semibold))
                if let location = post.location {
                    Text(location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var actions: some View {
        HStack(spacing: 16) {
            Button(action: onLike) {
                Label {
                    Text(post.likeCount, format: .number.notation(.compactName))
                } icon: {
                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(post.isLiked ? .red : .primary)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.selection, trigger: post.isLiked)
            .accessibilityLabel(post.isLiked ? "Unlike" : "Like")
            .accessibilityValue("\(post.likeCount) likes")

            Label {
                Text(post.commentCount, format: .number.notation(.compactName))
            } icon: {
                Image(systemName: "bubble.right")
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(post.commentCount) comments")
        }
        .font(.body.weight(.medium))
    }
}

#Preview {
    PostCardView(post: Post(MockAPIServer.bundledPosts()[0]), onLike: {}, onAuthorTap: {})
}
