#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("ExternalPhotoIntakeCenter")
struct ExternalPhotoIntakeCenterTests {

    @MainActor
    @Test("accepts RAW URLs through the shared intake policy")
    func acceptsRAWURLsThroughSharedIntakePolicy() throws {
        let suiteName =
            "PhotoMemo.ExternalPhotoIntakeCenterTests.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let intakeDirectoryURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )
        defer {
            try? FileManager.default.removeItem(
                at: intakeDirectoryURL
            )
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let center =
            ExternalPhotoIntakeCenter(
                intakeStore:
                    ExternalPhotoIntakeStore(
                        defaults: defaults,
                        intakeDirectoryURL:
                            intakeDirectoryURL
                    ),
                settingsService:
                    SettingsService(
                        defaults: defaults
                    )
            )
        let rawURL =
            URL(fileURLWithPath: "/tmp/IMG_0001.dng")
        let unsupportedURL =
            URL(fileURLWithPath: "/tmp/notes.txt")

        center.submit(
            urls: [
                rawURL,
                rawURL,
                unsupportedURL
            ],
            source: .quickAction
        )

        let request =
            try #require(
                center.drainPendingRequests().first
            )

        #expect(
            request.urls.map(\.lastPathComponent)
            == ["IMG_0001.dng"]
        )
    }
}
#endif
