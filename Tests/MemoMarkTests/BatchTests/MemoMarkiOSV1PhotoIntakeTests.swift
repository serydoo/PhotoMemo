#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import MemoMark

@Suite("MemoMark iOS V1 photo intake")
struct MemoMarkiOSV1PhotoIntakeTests {

    @Test("keeps supported image URLs and removes duplicates")
    func keepsSupportedImageURLsAndRemovesDuplicates() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.heic"),
            URL(fileURLWithPath: "/tmp/a.heic"),
            URL(fileURLWithPath: "/tmp/b.jpeg"),
            URL(fileURLWithPath: "/tmp/c.dng"),
            URL(fileURLWithPath: "/tmp/c.txt")
        ]

        let resolved = PhotoIntakeURLResolver.resolve(urls)

        #expect(resolved.count == 3)
        #expect(
            resolved.map(\.lastPathComponent)
            == ["a.heic", "b.jpeg", "c.dng"]
        )
    }

    @Test("builds a temporary URL using the suggested filename when available")
    func buildsTemporaryURLUsingSuggestedFilename() throws {
        let url =
            try PhotoIntakeURLResolver.makeTemporaryURL(
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
            try PhotoIntakeURLResolver
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

    @Test("stale intake cleanup removes only MemoMark picker temporary files")
    func staleIntakeCleanupStaysInsidePickerDirectory() throws {
        let pickerURL =
            try PhotoIntakeURLResolver.makeTemporaryURL(
                suggestedFileName: "stale.heic",
                contentType: .heic
            )
        let outsideURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "MemoMarkPickerOutside-\(UUID().uuidString).heic"
            )
        try Data([0x01]).write(to: pickerURL)
        try Data([0x02]).write(to: outsideURL)
        let symlinkURL =
            pickerURL.deletingLastPathComponent()
            .appendingPathComponent(
                "outside-link-\(UUID().uuidString).heic"
            )
        try FileManager.default.createSymbolicLink(
            at: symlinkURL,
            withDestinationURL: outsideURL
        )
        defer {
            try? FileManager.default.removeItem(at: pickerURL)
            try? FileManager.default.removeItem(at: symlinkURL)
            try? FileManager.default.removeItem(at: outsideURL)
        }

        PhotoIntakeURLResolver.discardTemporaryPickerFiles(
            [pickerURL, outsideURL, symlinkURL]
        )

        #expect(
            !FileManager.default.fileExists(
                atPath: pickerURL.path
            )
        )
        #expect(
            FileManager.default.fileExists(
                atPath: outsideURL.path
            )
        )
        #expect(
            FileManager.default.fileExists(
                atPath: symlinkURL.path
            )
        )
    }

    @Test("V1 quick action unsupported message uses input policy diagnostics")
    func v1QuickActionUnsupportedMessageUsesInputPolicyDiagnostics() {
        let message =
            PhotoIntakeUnsupportedMessagePresenter
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
            PhotoIntakeUnsupportedMessagePresenter
            .message(for: [])
            == PhotoIntakeUnsupportedMessagePresenter
            .fallbackMessage
        )
        #expect(
            PhotoIntakeUnsupportedMessagePresenter
            .message(for: [.heic])
            == PhotoIntakeUnsupportedMessagePresenter
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
            await PhotoProcessingQuickActionCoordinator
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

    @Test("saves current configuration before submitting picked photo payloads")
    func savesCurrentConfigurationBeforeSubmittingPickedPhotoPayloads() async {
        var events: [String] = []
        let item =
            ExternalPhotoIntakeItem(
                managedURL:
                    URL(fileURLWithPath: "/tmp/IMG_6093.HEIC"),
                originalFileName:
                    "IMG_6093.HEIC",
                sourceIdentifier:
                    "live-photo-local-identifier",
                contentTypeIdentifier:
                    UTType("com.apple.live-photo")?.identifier
            )

        let result =
            await PhotoProcessingQuickActionCoordinator
            .processPickedPhotoItems(
                saveCurrentConfiguration: {
                    events.append("save")
                    return true
                },
                importItems: {
                    events.append("import")
                    return [
                        item
                    ]
                },
                submit: { submittedItems in
                    events.append(
                        "submit:\(submittedItems.count)"
                    )
                }
            )

        #expect(result.status == .submitted)
        #expect(
            result.submittedURLs
            == [
                item.managedURL
            ]
        )
        #expect(
            result.submittedItems == [
                item
            ]
        )
        #expect(events == ["save", "import", "submit:1"])
    }

    @Test("picked photo payloads retain the snapshot captured before import")
    func pickedPhotoPayloadsRetainFrozenConfiguration() async {
        let snapshot = BatchConfigurationSnapshot(
            template: .classicWhite,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "frozen",
            selectedAlbumIdentifier: "album-before-import"
        )
        let item = ExternalPhotoIntakeItem(
            managedURL: URL(fileURLWithPath: "/tmp/frozen.jpg")
        )
        var receivedSnapshot: BatchConfigurationSnapshot?

        let result =
            await PhotoProcessingQuickActionCoordinator
            .processPickedPhotoItems(
                saveCurrentConfiguration: {
                    snapshot
                },
                importItems: {
                    try? await Task.sleep(
                        nanoseconds: 1_000_000
                    )
                    return [item]
                },
                submit: { _, submittedSnapshot in
                    receivedSnapshot = submittedSnapshot
                }
            )

        #expect(result.status == .submitted)
        #expect(receivedSnapshot == snapshot)
    }

    @Test("does not import or submit when configuration save fails")
    func doesNotSubmitWhenConfigurationSaveFails() async {
        var events: [String] = []

        let result =
            await PhotoProcessingQuickActionCoordinator
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

    @Test("runtime reports configuration failure and empty import without submission")
    @MainActor
    func runtimeReportsFailureAndEmptyImportWithoutSubmission() async {
        let coordinator = PhotoIntakeRuntimeCoordinator()
        var submitCount = 0

        let failedSave = await coordinator.perform(
            requestedCount: 1,
            saveCurrentConfiguration: { nil },
            importItems: {
                Issue.record("Import must not start when configuration save fails.")
                return []
            },
            submit: { _, _ in submitCount += 1 }
        )

        let emptyImport = await coordinator.perform(
            requestedCount: 1,
            saveCurrentConfiguration: { Self.snapshot },
            importItems: { [] },
            submit: { _, _ in submitCount += 1 }
        )

        #expect(failedSave?.status == .configurationSaveFailed)
        #expect(emptyImport?.status == .noSupportedPhotos)
        #expect(submitCount == 0)
    }

    @Test("cancelling an active import prevents submission and stale UI completion")
    @MainActor
    func cancellationPreventsSubmissionAndCompletion() async {
        let coordinator = PhotoIntakeRuntimeCoordinator()
        let gate = PhotoIntakeImportGate()
        var submittedItems: [ExternalPhotoIntakeItem] = []
        var discardedItems: [ExternalPhotoIntakeItem] = []

        let task = Task { @MainActor in
            await coordinator.perform(
                requestedCount: 1,
                saveCurrentConfiguration: { Self.snapshot },
                importItems: { await gate.wait() },
                submit: { items, _ in submittedItems = items },
                discardUnsubmittedItems: { discardedItems = $0 }
            )
        }

        await gate.waitUntilSuspended()
        coordinator.cancelActiveRequest()
        gate.resume([Self.item(named: "cancelled.heic")])

        #expect(await task.value == nil)
        #expect(submittedItems.isEmpty)
        #expect(
            discardedItems
            == [Self.item(named: "cancelled.heic")]
        )
    }

    @Test("task cancellation clears its request identity and keeps the runtime reusable")
    @MainActor
    func taskCancellationClearsIdentityAndKeepsRuntimeReusable() async {
        let coordinator = PhotoIntakeRuntimeCoordinator()
        let gate = PhotoIntakeImportGate()
        let cancelledItem = Self.item(named: "task-cancelled.heic")
        let nextItem = Self.item(named: "next.heic")
        var submittedItems: [ExternalPhotoIntakeItem] = []
        var discardedItems: [ExternalPhotoIntakeItem] = []

        let cancelledTask = Task { @MainActor in
            await coordinator.perform(
                requestedCount: 1,
                saveCurrentConfiguration: { Self.snapshot },
                importItems: { await gate.wait() },
                submit: { items, _ in submittedItems.append(contentsOf: items) },
                discardUnsubmittedItems: { discardedItems = $0 }
            )
        }

        await gate.waitUntilSuspended()
        cancelledTask.cancel()
        gate.resume([cancelledItem])
        #expect(await cancelledTask.value == nil)

        let nextResult = await coordinator.perform(
            requestedCount: 1,
            saveCurrentConfiguration: { Self.snapshot },
            importItems: { [nextItem] },
            submit: { items, _ in submittedItems.append(contentsOf: items) }
        )

        #expect(discardedItems == [cancelledItem])
        #expect(submittedItems == [nextItem])
        #expect(nextResult?.status == .submitted)
    }

    @Test("a newer intake request rejects an older delayed completion")
    @MainActor
    func newerRequestRejectsOlderDelayedCompletion() async {
        let coordinator = PhotoIntakeRuntimeCoordinator()
        let firstGate = PhotoIntakeImportGate()
        let firstItem = Self.item(named: "first.heic")
        let secondItem = Self.item(named: "second.heic")
        var submittedItems: [ExternalPhotoIntakeItem] = []

        let firstTask = Task { @MainActor in
            await coordinator.perform(
                requestedCount: 1,
                saveCurrentConfiguration: { Self.snapshot },
                importItems: { await firstGate.wait() },
                submit: { items, _ in submittedItems.append(contentsOf: items) }
            )
        }

        await firstGate.waitUntilSuspended()
        let secondResult = await coordinator.perform(
            requestedCount: 1,
            saveCurrentConfiguration: { Self.snapshot },
            importItems: { [secondItem] },
            submit: { items, _ in submittedItems.append(contentsOf: items) }
        )
        firstGate.resume([firstItem])

        #expect(await firstTask.value == nil)
        #expect(secondResult?.status == .submitted)
        #expect(submittedItems == [secondItem])
    }

    private static var snapshot: BatchConfigurationSnapshot {
        BatchConfigurationSnapshot(
            template: .classicWhite,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier: "test-album"
        )
    }

    private static func item(
        named name: String
    ) -> ExternalPhotoIntakeItem {
        ExternalPhotoIntakeItem(
            managedURL: URL(fileURLWithPath: "/tmp/\(name)")
        )
    }
}

@MainActor
private final class PhotoIntakeImportGate {

    private var continuation:
        CheckedContinuation<[ExternalPhotoIntakeItem], Never>?

    func wait() async -> [ExternalPhotoIntakeItem] {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func waitUntilSuspended() async {
        while continuation == nil {
            await Task.yield()
        }
    }

    func resume(_ items: [ExternalPhotoIntakeItem]) {
        continuation?.resume(returning: items)
        continuation = nil
    }
}
#endif
