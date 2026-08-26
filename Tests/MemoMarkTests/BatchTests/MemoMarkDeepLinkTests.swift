import Foundation
import Testing
@testable import MemoMark

@Suite("MemoMark deep links")
struct MemoMarkDeepLinkTests {

    @Test("Parses the share deep link host")
    func parsesShareDeepLinkHost() throws {

        let deepLink =
            try #require(
                MemoMarkDeepLink(
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
                MemoMarkDeepLink(
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
            MemoMarkDeepLink(
                url: URL(
                    string: "file:///tmp/example.jpg"
                )!
            ) == nil
        )
        #expect(
            MemoMarkDeepLink(
                url: URL(
                    string: "https://example.com/share"
                )!
            ) == nil
        )
    }

    @Test("Emits the MemoMark share URL")
    func emitsMemoMarkShareURL() {

        #expect(
            MemoMarkDeepLink
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
        let deepLink = MemoMarkDeepLink.processing(jobID: jobID)

        #expect(
            MemoMarkDeepLink(url: deepLink.url)
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
            MemoMarkDeepLink(
                url: URL(string: "memomark://processing/not-a-job")!
            ) == nil
        )
    }
}
