//
//  FeedCache.swift
//  Uma
//

import Foundation
import OSLog

nonisolated protocol FeedCache: Sendable {
    func load() async -> [Post]
    func save(_ posts: [Post]) async
}

/// Persists the most recently loaded feed as JSON in the Caches directory.
actor FileFeedCache: FeedCache {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Uma", category: "FeedCache")

    init(fileURL: URL = .cachesDirectory.appending(path: "feed-cache.json")) {
        self.fileURL = fileURL
    }

    func load() -> [Post] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        do {
            return try decoder.decode([Post].self, from: data)
        } catch {
            logger.error("Discarding unreadable feed cache: \(error.localizedDescription)")
            return []
        }
    }

    func save(_ posts: [Post]) {
        do {
            try encoder.encode(posts).write(to: fileURL, options: .atomic)
        } catch {
            logger.error("Failed to write feed cache: \(error.localizedDescription)")
        }
    }
}
