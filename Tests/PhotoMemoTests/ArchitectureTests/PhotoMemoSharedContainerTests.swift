import Foundation
import Testing
@testable import PhotoMemo

@Suite("PhotoMemo shared container")
struct PhotoMemoSharedContainerTests {

    @Test("handoff readiness is ready only when App Group defaults and container URL resolve")
    func handoffReadinessRequiresAppGroupDefaultsAndContainerURL() {

        let appGroupURL =
            URL(fileURLWithPath: "/tmp/PhotoMemoAppGroup")
        let readiness =
            PhotoMemoSharedContainer
            .handoffReadiness(
                userDefaultsProvider: { _ in
                    UserDefaults.standard
                },
                containerURLProvider: { _ in
                    appGroupURL
                },
                fallbackBaseDirectoryURLProvider: {
                    URL(fileURLWithPath: "/tmp/Fallback")
                }
            )

        #expect(readiness.isHandoffReady)
        #expect(readiness.userDefaultsSuiteAvailable)
        #expect(readiness.appGroupContainerAvailable)
        #expect(!readiness.usesFallbackBaseDirectory)
        #expect(readiness.baseDirectoryURL == appGroupURL)
        #expect(
            readiness.diagnosticMessage
            .contains("handoffReady=true")
        )
    }

    @Test("handoff readiness exposes fallback when App Group resolution fails")
    func handoffReadinessExposesFallbackWhenAppGroupResolutionFails() {

        let fallbackURL =
            URL(fileURLWithPath: "/tmp/PhotoMemoFallback")
        let readiness =
            PhotoMemoSharedContainer
            .handoffReadiness(
                userDefaultsProvider: { _ in nil },
                containerURLProvider: { _ in nil },
                fallbackBaseDirectoryURLProvider: {
                    fallbackURL
                }
            )

        #expect(!readiness.isHandoffReady)
        #expect(!readiness.userDefaultsSuiteAvailable)
        #expect(!readiness.appGroupContainerAvailable)
        #expect(readiness.usesFallbackBaseDirectory)
        #expect(readiness.baseDirectoryURL == fallbackURL)
        #expect(
            readiness.diagnosticMessage
            .contains("handoffReady=false")
        )
        #expect(
            readiness.diagnosticMessage
            .contains("usesFallbackBaseDirectory=true")
        )
    }

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
