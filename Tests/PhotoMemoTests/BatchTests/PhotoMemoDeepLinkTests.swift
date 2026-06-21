import Foundation
import Testing
@testable import PhotoMemo

@Suite("PhotoMemo deep links")
struct PhotoMemoDeepLinkTests {

    @Test("Parses the share deep link host")
    func parsesShareDeepLinkHost() throws {

        let deepLink =
            try #require(
                PhotoMemoDeepLink(
                    url: URL(
                        string: "photomemo://share"
                    )!
                )
            )

        #expect(
            deepLink == .share
        )
    }

    @Test("Parses the share deep link path")
    func parsesShareDeepLinkPath() throws {

        let deepLink =
            try #require(
                PhotoMemoDeepLink(
                    url: URL(
                        string: "photomemo:///share"
                    )!
                )
            )

        #expect(
            deepLink == .share
        )
    }

    @Test("Ignores non-PhotoMemo URLs")
    func ignoresNonPhotoMemoURLs() {

        #expect(
            PhotoMemoDeepLink(
                url: URL(
                    string: "file:///tmp/example.jpg"
                )!
            ) == nil
        )
        #expect(
            PhotoMemoDeepLink(
                url: URL(
                    string: "https://example.com/share"
                )!
            ) == nil
        )
    }
}
