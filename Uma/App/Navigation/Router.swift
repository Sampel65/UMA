//
//  Router.swift
//  Uma
//

import Observation

/// Owns the navigation stack so screens request navigation by intent rather than constructing destinations.
@Observable
final class Router {
    var path: [Route] = []

    func push(_ route: Route) {
        path.append(route)
    }
}
