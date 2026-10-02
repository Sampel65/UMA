//
//  NetworkMonitor.swift
//  Uma
//

import Network
import Observation

@Observable
final class NetworkMonitor {
    private(set) var isConnected = true

    @ObservationIgnored private let monitor = NWPathMonitor()

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            Task { @MainActor in
                guard let self, self.isConnected != isConnected else { return }
                self.isConnected = isConnected
            }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }

    deinit {
        monitor.cancel()
    }
}
