#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("MemoMark iOS V1 photo intake")
struct PhotoMemoiOSV1PhotoIntakeTests {

    @Test("keeps supported image URLs and removes duplicates")
    func keepsSupportedImageURLsAndRemovesDuplicates() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.heic"),
            URL(fileURLWithPath: "/tmp/a.heic"),
            URL(fileURLWithPath: "/tmp/b.jpeg"),
            URL(fileURLWithPath: "/tmp/c.dng"),
            URL(fileURLWithPath: "/tmp/c.txt")
        ]

        let resolved = V1PhotoIntakeURLResolver.resolve(urls)

        #expect(resolved.count == 3)
        #expect(
            resolved.map(\.lastPathComponent)
            == ["a.heic", "b.jpeg", "c.dng"]
        )
    }

    @Test("builds a temporary URL using the suggested filename when available")
    func buildsTemporaryURLUsingSuggestedFilename() throws {
        let url =
            try V1PhotoIntakeURLResolver.makeTemporaryURL(
                suggestedFileName: "IMG_0001.HEIC",
                contentType: .heic
            )

        #expect(url.pathExtension.lowercased() == "heic")
        #expect(url.lastPathComponent.contains("IMG_0001"))
    }

    @Test("copies file representations before submitting picker URLs")
    func copiesFileRepresentationsBeforeSubmittingPickerURLs() throws {
        let sourceDirectory =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "MemoMarkV1PhotoIntakeTests-\(UUID().uuidString)",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: sourceDirectory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: sourceDirectory
            )
        }

        let sourceURL =
            sourceDirectory
            .appendingPathComponent("IMG_1001")
            .appendingPathExtension("HEIC")

        let data =
            Data([0x01, 0x02, 0x03, 0x04])

        try data.write(
            to: sourceURL
        )

        let copiedURL =
            try V1PhotoIntakeURLResolver
            .copyTemporaryFileRepresentation(
                from: sourceURL,
                contentType: .heic
            )

        #expect(
            copiedURL.standardizedFileURL
            != sourceURL.standardizedFileURL
        )
        #expect(
            copiedURL.pathExtension.lowercased()
            == "heic"
        )
        #expect(
            try Data(contentsOf: copiedURL)
            == data
        )

        try? FileManager.default.removeItem(
            at: copiedURL
        )
    }

    @Test("V1 quick action unsupported message uses input policy diagnostics")
    func v1QuickActionUnsupportedMessageUsesInputPolicyDiagnostics() {
        let message =
            V1PhotoIntakeUnsupportedMessagePresenter
            .message(
                for: [
                    .gif
                ]
            )

        let verdict =
            PhotoProcessingInputPolicy
            .standard
            .verdict(
                contentType: .gif,
                pixelWidth: 1,
                pixelHeight: 1
            )

        #expect(message.contains(verdict.title))
        #expect(message.contains(verdict.message))
    }

    @Test("V1 quick action unsupported message keeps fallback when no rejection is known")
    func v1QuickActionUnsupportedMessageKeepsFallbackWhenNoRejectionIsKnown() {
        #expect(
            V1PhotoIntakeUnsupportedMessagePresenter
            .message(for: [])
            == V1PhotoIntakeUnsupportedMessagePresenter
            .fallbackMessage
        )
        #expect(
            V1PhotoIntakeUnsupportedMessagePresenter
            .message(for: [.heic])
            == V1PhotoIntakeUnsupportedMessagePresenter
            .fallbackMessage
        )
    }

    @Test("saves current configuration before submitting picked photos")
    func savesCurrentConfigurationBeforeSubmittingPickedPhotos() async {
        var events: [String] = []
        let urls = [
            URL(fileURLWithPath: "/tmp/a.heic")
        ]

        let result =
            await V1PhotoProcessingQuickActionCoordinator
            .processPickedPhotos(
                saveCurrentConfiguration: {
                    events.append("save")
                    return true
                },
                importURLs: {
                    events.append("import")
                    return urls
                },
                submit: { submittedURLs in
                    events.append("submit:\(submittedURLs.count)")
                }
            )

        #expect(result.status == .submitted)
        #expect(result.submittedURLs == urls)
        #expect(events == ["save", "import", "submit:1"])
    }

    @Test("does not import or submit when configuration save fails")
    func doesNotSubmitWhenConfigurationSaveFails() async {
        var events: [String] = []

        let result =
            await V1PhotoProcessingQuickActionCoordinator
            .processPickedPhotos(
                saveCurrentConfiguration: {
                    events.append("save")
                    return false
                },
                importURLs: {
                    events.append("import")
                    return [
                        URL(fileURLWithPath: "/tmp/a.heic")
                    ]
                },
                submit: { _ in
                    events.append("submit")
                }
            )

        #expect(result.status == .configurationSaveFailed)
        #expect(result.submittedURLs.isEmpty)
        #expect(events == ["save"])
    }
}
#endif
