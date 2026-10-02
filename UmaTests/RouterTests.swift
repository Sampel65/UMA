//
//  RouterTests.swift
//  UmaTests
//

import Testing
@testable import Uma

struct RouterTests {
    @Test func pushAppendsRoutesInOrder() {
        let router = Router()
        let author = Author.fixture()

        router.push(.profile(author))
        router.push(.post(id: "1"))

        #expect(router.path == [.profile(author), .post(id: "1")])
    }
}
