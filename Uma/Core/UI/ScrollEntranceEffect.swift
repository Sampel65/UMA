//
//  ScrollEntranceEffect.swift
//  Uma
//

import SwiftUI

extension View {
    /// Fades and lifts the view in as it scrolls up from the bottom edge, tracking the finger.
    func scrollEntranceEffect() -> some View {
        modifier(ScrollEntranceEffect())
    }
}

private struct ScrollEntranceEffect: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let isMotionEnabled = !reduceMotion
        // Only the bottom edge animates, so tall posts never fade while still being read at the top.
        content.scrollTransition(topLeading: .identity, bottomTrailing: .interactive) { effect, phase in
            let progress = abs(phase.value)
            return effect
                .opacity(1 - progress * 0.6)
                .scaleEffect(isMotionEnabled ? 1 - progress * 0.06 : 1)
                .offset(y: isMotionEnabled ? progress * 40 : 0)
        }
    }
}
