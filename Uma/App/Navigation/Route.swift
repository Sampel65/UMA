//
//  Route.swift
//  Uma
//

/// Every screen that can be pushed onto the navigation stack.
nonisolated enum Route: Hashable {
    case profile(Author)
    case post(id: Post.ID)
}
