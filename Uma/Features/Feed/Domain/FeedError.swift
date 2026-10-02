//
//  FeedError.swift
//  Uma
//

import Foundation

nonisolated enum FeedError: LocalizedError, Equatable {
    case offline
    case server

    var errorDescription: String? {
        switch self {
        case .offline: String(localized: "You're offline. Check your connection and try again.")
        case .server: String(localized: "We couldn't reach the server. Please try again.")
        }
    }
}
