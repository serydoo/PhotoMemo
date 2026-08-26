import Foundation
import Testing
@testable import MemoMark

@Suite("MemoMark shared container")
struct MemoMarkSharedContainerTests {

    @Test("handoff readiness is ready only when App Group defaults and container URL resolve")
    func handoffReadinessRequiresAppGroupDefaultsAndContainerURL() {

        let appGroupURL =
            URL(fileURLWithPath: "/tmp/MemoMarkAppGroup")
        let readiness =
            MemoMarkSharedContainer
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
        #expect(readiness.userDefaultsReadbackVerified)
        #expect(readiness.containerReadbackVerified)
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
            URL(fileURLWithPath: "/tmp/MemoMarkFallback")
        let readiness =
            MemoMarkSharedContainer
            .handoffReadiness(
                userDefaultsProvider: { _ in nil },
                containerURLProvider: { _ in nil },
                userDefaultsProbe: { _ in false },
                containerProbe: { _ in false },
                fallbackBaseDirectoryURLProvider: {
                    fallbackURL
                }
            )

        #expect(!readiness.isHandoffReady)
        #expect(!readiness.userDefaultsSuiteAvailable)
        #expect(!readiness.appGroupContainerAvailable)
        #expect(!readiness.userDefaultsReadbackVerified)
        #expect(!readiness.containerReadbackVerified)
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

    @Test("handoff readiness fails closed when either shared boundary cannot round-trip")
    func handoffReadinessRequiresRoundTripProbes() {
        let appGroupURL =
            URL(fileURLWithPath: "/tmp/MemoMarkAppGroupProbe")
        let readiness =
            MemoMarkSharedContainer.handoffReadiness(
                userDefaultsProvider: { _ in UserDefaults.standard },
                containerURLProvider: { _ in appGroupURL },
                userDefaultsProbe: { _ in true },
                containerProbe: { _ in false },
                fallbackBaseDirectoryURLProvider: {
                    URL(fileURLWithPath: "/tmp/Fallback")
                }
            )

        #expect(!readiness.isHandoffReady)
        #expect(readiness.userDefaultsReadbackVerified)
        #expect(!readiness.containerReadbackVerified)
    }

    @Test("handoff can attempt authoritative persistence when App Group capabilities resolve but advisory probes fail")
    func handoffAttemptDoesNotTreatAdvisoryProbeFailureAsCapabilityFailure() {
        let appGroupURL =
            URL(fileURLWithPath: "/tmp/MemoMarkAppGroupAdvisoryProbe")
        let readiness =
            MemoMarkSharedContainer.handoffReadiness(
                userDefaultsProvider: { _ in UserDefaults.standard },
                containerURLProvider: { _ in appGroupURL },
                userDefaultsProbe: { _ in false },
                containerProbe: { _ in false },
                fallbackBaseDirectoryURLProvider: {
                    URL(fileURLWithPath: "/tmp/Fallback")
                }
            )

        #expect(readiness.canAttemptHandoff)
        #expect(!readiness.isHandoffReady)
        #expect(readiness.userDefaultsSuiteAvailable)
        #expect(readiness.appGroupContainerAvailable)
    }

    @Test("ensureDirectory surfaces creation failures")
    func ensureDirectorySurfacesCreationFailures() throws {
        let rootURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "MemoMarkSharedContainerTests-\(UUID().uuidString)",
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
            try MemoMarkSharedContainer
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
