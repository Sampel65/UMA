//
//  ImageLoader.swift
//  Uma
//

import UIKit

/// Two-tier image cache: decoded images in memory (`NSCache`) and raw responses on disk (`URLCache`),
/// with in-flight request de-duplication so cells scrolling back into view never refetch.
actor ImageLoader {
    static let shared = ImageLoader()

    private let session: URLSession
    private let memoryCache = NSCache<NSURL, UIImage>()
    private var inFlightTasks: [URL: Task<UIImage, any Error>] = [:]

    /// - Parameters:
    ///   - decodedCacheLimit: Bytes of decoded bitmaps kept in memory; `NSCache` also evicts under memory pressure.
    ///   - diskCapacity: Bytes of raw image responses kept on disk.
    init(decodedCacheLimit: Int = 150 * 1_024 * 1_024, diskCapacity: Int = 250 * 1_024 * 1_024) {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 10 * 1_024 * 1_024,
            diskCapacity: diskCapacity,
            directory: .cachesDirectory.appending(path: "ImageCache")
        )
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: configuration)
        memoryCache.totalCostLimit = decodedCacheLimit
    }

    func image(for url: URL) async throws -> UIImage {
        if let cached = memoryCache.object(forKey: url as NSURL) { return cached }
        if let task = inFlightTasks[url] { return try await task.value }

        let task = Task { [session] in
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            guard let image = UIImage(data: data) else { throw URLError(.cannotDecodeContentData) }
            return await image.byPreparingForDisplay() ?? image
        }
        inFlightTasks[url] = task
        defer { inFlightTasks[url] = nil }

        let image = try await task.value
        memoryCache.setObject(image, forKey: url as NSURL, cost: image.decodedByteCount)
        return image
    }
}

private extension UIImage {
    /// Approximate size of the decoded RGBA bitmap.
    nonisolated var decodedByteCount: Int {
        Int(size.width * scale * size.height * scale) * 4
    }
}
