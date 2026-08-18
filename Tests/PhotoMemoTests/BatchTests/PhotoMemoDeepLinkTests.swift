import Foundation
import Testing
@testable import PhotoMemo

@Suite("MemoMark deep links")
struct PhotoMemoDeepLinkTests {

    @Test("Parses the share deep link host")
    func parsesShareDeepLinkHost() throws {

        let deepLink =
            try #require(
                PhotoMemoDeepLink(
                    url: URL(
                        string: "memomark://share"
                    )!
                )
            )

        #expect(
            deepLink == .share
        )
    }

    @Test("Parses the legacy share deep link path")
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

    @Test("Ignores non-MemoMark URLs")
    func ignoresNonMemoMarkURLs() {

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

    @Test("Emits the MemoMark share URL")
    func emitsMemoMarkShareURL() {

        #expect(
            PhotoMemoDeepLink
                .share
                .url
                .absoluteString
            == "memomark://share"
        )
    }

    @Test("Parses and emits a processing job deep link")
    func parsesAndEmitsProcessingJobDeepLink() throws {
        let jobID = UUID(
            uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
        )!
        let deepLink = PhotoMemoDeepLink.processing(jobID: jobID)

        #expect(
            PhotoMemoDeepLink(url: deepLink.url)
            == deepLink
        )
        #expect(
            deepLink.url.absoluteString
            == "memomark://processing/AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
        )
    }

    @Test("Rejects a processing deep link without a valid job ID")
    func rejectsInvalidProcessingJobDeepLink() {
        #expect(
            PhotoMemoDeepLink(
                url: URL(string: "memomark://processing/not-a-job")!
            ) == nil
        )
    }
}
