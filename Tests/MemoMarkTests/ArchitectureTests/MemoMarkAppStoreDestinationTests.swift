import Foundation
import Testing
@testable import MemoMark

@Suite("Settings App Store destinations")
struct MemoMarkAppStoreDestinationTests {
    @Test("manual review action targets MemoMark's actual write-review page")
    func manualReviewDestination() throws {
        let components = try #require(URLComponents(
            url: MemoMarkAppStoreDestination.review.url,
            resolvingAgainstBaseURL: false
        ))
        #expect(components.scheme == "https")
        #expect(components.host == "apps.apple.com")
        #expect(components.path == "/app/id6788331801")
        #expect(components.queryItems == [URLQueryItem(name: "action", value: "write-review")])
    }

    @Test("manual update action opens the product page without submitting a review")
    func updateDestination() throws {
        let components = try #require(URLComponents(
            url: MemoMarkAppStoreDestination.updates.url,
            resolvingAgainstBaseURL: false
        ))
        #expect(components.scheme == "https")
        #expect(components.host == "apps.apple.com")
        #expect(components.path == "/app/id6788331801")
        #expect(components.queryItems == nil)
        #expect(MemoMarkAppStoreDestination.review.url != MemoMarkAppStoreDestination.updates.url)
    }

    @Test("destinations let App Store resolve storefront and carry no user context")
    func noStorefrontOrUserContext() {
        for destination in [MemoMarkAppStoreDestination.review, .updates] {
            #expect(destination.url.user == nil)
            #expect(destination.url.password == nil)
            #expect(destination.url.fragment == nil)
            #expect(destination.url.pathComponents == ["/", "app", "id6788331801"])
        }
    }
}
