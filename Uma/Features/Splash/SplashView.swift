//
//  SplashView.swift
//  Uma
//

import SwiftUI

/// Shown briefly on launch while the first feed page loads underneath. The background matches the
/// system-generated launch screen so the hand-off from launch to splash is seamless.
struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Self.brandGradient)
                    .frame(width: 112, height: 112)
                    .overlay {
                        Text("U")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: .pink.opacity(0.35), radius: 24, y: 12)

                Text("Uma")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
            }
            .scaleEffect(isVisible || reduceMotion ? 1 : 0.8)
            .opacity(isVisible ? 1 : 0)
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 2) {
                Text("from")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("UMA Social")
                    .font(.headline)
                    .foregroundStyle(Self.brandGradient)
            }
            .padding(.bottom, 24)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.3)) { isVisible = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Uma")
    }

    private static let brandGradient = LinearGradient(
        colors: [.purple, .pink, .orange],
        startPoint: .topTrailing,
        endPoint: .bottomLeading
    )
}

#Preview {
    SplashView()
}
