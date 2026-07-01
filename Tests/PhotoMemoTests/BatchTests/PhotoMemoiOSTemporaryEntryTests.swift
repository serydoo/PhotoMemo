import Foundation
import Testing
@testable import PhotoMemo

@Suite("PhotoMemo iOS temporary entry")
struct PhotoMemoiOSTemporaryEntryTests {

    @Test("Falls back to the provided default entry when storage is empty or invalid")
    func fallsBackToProvidedDefaultEntry() {

        #expect(
            PhotoMemoiOSTemporaryEntry.resolve(
                storedValue: nil,
                defaultEntry: .configurationCenter
            ) == .configurationCenter
        )
        #expect(
            PhotoMemoiOSTemporaryEntry.resolve(
                storedValue: "unknown-entry",
                defaultEntry: .v1Preview
            ) == .v1Preview
        )
    }

    @Test("Resolves known raw values without changing compatibility")
    func resolvesKnownRawValues() {

        #expect(
            PhotoMemoiOSTemporaryEntry.resolve(
                storedValue: "configurationCenter",
                defaultEntry: .v1Preview
            ) == .configurationCenter
        )
        #expect(
            PhotoMemoiOSTemporaryEntry.resolve(
                storedValue: "v1Preview",
                defaultEntry: .configurationCenter
            ) == .v1Preview
        )
    }

    @Test("Keeps standard iOS and V1 temporary entry storage isolated")
    func keepsStandardAndV1TemporaryEntryStorageIsolated() {

        #expect(
            PhotoMemoiOSTemporaryEntryConfiguration.standard.storageKey
            == "photomemo.ios.temporaryEntry"
        )
        #expect(
            PhotoMemoiOSTemporaryEntryConfiguration.standard.defaultEntry
            == .configurationCenter
        )
        #expect(
            PhotoMemoiOSTemporaryEntryConfiguration.v1.storageKey
            == "photomemo.ios.v1.temporaryEntry"
        )
        #expect(
            PhotoMemoiOSTemporaryEntryConfiguration.v1.defaultEntry
            == .v1Preview
        )
    }
}
