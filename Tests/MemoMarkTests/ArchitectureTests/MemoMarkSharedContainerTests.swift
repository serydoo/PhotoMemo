import Foundation
import Testing
@testable import MemoMark

@Suite("MemoMark shared container")
struct MemoMarkSharedContainerTests {

    @Test("Legacy migration copies an eligible MemoMark-owned key")
    func legacyMigrationCopiesEligibleKey() throws {
        let context = try makeDefaultsMigrationContext()
        defer { context.removePersistentDomains() }
        let eligibleKey = "photomemo.selectedTemplate"
        context.legacy.set("legacy-value", forKey: eligibleKey)

        MemoMarkSharedContainer.migrateLegacyDefaultsIfNeeded(
            from: context.legacy,
            into: context.shared
        )

        #expect(context.shared.string(forKey: eligibleKey) == "legacy-value")
    }

    @Test("Legacy migration preserves an existing shared value")
    func legacyMigrationPreservesExistingSharedValue() throws {
        let context = try makeDefaultsMigrationContext()
        defer { context.removePersistentDomains() }
        let eligibleKey = "photomemo.selectedTemplate"
        context.legacy.set("legacy-value", forKey: eligibleKey)
        context.shared.set("shared-value", forKey: eligibleKey)

        MemoMarkSharedContainer.migrateLegacyDefaultsIfNeeded(
            from: context.legacy,
            into: context.shared
        )

        #expect(context.shared.string(forKey: eligibleKey) == "shared-value")
    }

    @Test("Legacy migration excludes unrelated defaults")
    func legacyMigrationExcludesUnrelatedDefaults() throws {
        let context = try makeDefaultsMigrationContext()
        defer { context.removePersistentDomains() }
        let unrelatedKey = "unrelated.framework.preference"
        context.legacy.set("private-value", forKey: unrelatedKey)

        MemoMarkSharedContainer.migrateLegacyDefaultsIfNeeded(
            from: context.legacy,
            into: context.shared
        )

        #expect(context.shared.object(forKey: unrelatedKey) == nil)
    }

    @Test("Legacy migration runs only once")
    func legacyMigrationIsIdempotent() throws {
        let context = try makeDefaultsMigrationContext()
        defer { context.removePersistentDomains() }
        let firstEligibleKey = "photomemo.selectedTemplate"
        let laterEligibleKey = "photomemo.selectedBadge"
        context.legacy.set("first-value", forKey: firstEligibleKey)

        MemoMarkSharedContainer.migrateLegacyDefaultsIfNeeded(
            from: context.legacy,
            into: context.shared
        )
        context.legacy.set("later-value", forKey: laterEligibleKey)
        MemoMarkSharedContainer.migrateLegacyDefaultsIfNeeded(
            from: context.legacy,
            into: context.shared
        )

        #expect(context.shared.string(forKey: firstEligibleKey) == "first-value")
        #expect(context.shared.object(forKey: laterEligibleKey) == nil)
    }

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
                userDefaultsProbe: { _ in true },
                containerProbe: { _ in true },
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

private extension MemoMarkSharedContainerTests {

    struct DefaultsMigrationContext {
        let legacy: UserDefaults
        let shared: UserDefaults
        let legacySuiteName: String
        let sharedSuiteName: String

        func removePersistentDomains() {
            legacy.removePersistentDomain(
                forName: legacySuiteName
            )
            shared.removePersistentDomain(
                forName: sharedSuiteName
            )
        }
    }

    func makeDefaultsMigrationContext() throws
    -> DefaultsMigrationContext {
        let legacySuiteName =
            "MemoMarkSharedContainerTests.legacy.\(UUID().uuidString)"
        let sharedSuiteName =
            "MemoMarkSharedContainerTests.shared.\(UUID().uuidString)"
        let legacy = try #require(
            UserDefaults(suiteName: legacySuiteName)
        )
        let shared = try #require(
            UserDefaults(suiteName: sharedSuiteName)
        )
        legacy.removePersistentDomain(
            forName: legacySuiteName
        )
        shared.removePersistentDomain(
            forName: sharedSuiteName
        )

        return DefaultsMigrationContext(
            legacy: legacy,
            shared: shared,
            legacySuiteName: legacySuiteName,
            sharedSuiteName: sharedSuiteName
        )
    }
}
