import Foundation
import Testing
@testable import PhotoMemo

@Suite("PhotoMemo shared container")
struct PhotoMemoSharedContainerTests {

    @Test("ensureDirectory surfaces creation failures")
    func ensureDirectorySurfacesCreationFailures() throws {
        let rootURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "PhotoMemoSharedContainerTests-\(UUID().uuidString)",
                isDirectory: true
            )
        let fileURL =
            rootURL
            .appendingPathComponent(
                "not-a-directory",
                isDirectory: false
            )
        let blockedDirectoryURL =
            fileURL
            .appendingPathComponent(
                "child",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true
        )
        try Data("blocking-file".utf8)
            .write(
                to: fileURL
            )
        defer {
            try? FileManager.default
                .removeItem(
                    at: rootURL
                )
        }

        do {
            try PhotoMemoSharedContainer
                .ensureDirectory(
                    at: blockedDirectoryURL
                )
            Issue.record("Expected directory creation to fail")
        } catch SharedContainerError
            .createDirectoryFailed(let url, let underlying) {
            #expect(url == blockedDirectoryURL)
            #expect(
                String(describing: underlying)
                .isEmpty == false
            )
        } catch {
            Issue.record("Expected SharedContainerError")
        }
    }
}
