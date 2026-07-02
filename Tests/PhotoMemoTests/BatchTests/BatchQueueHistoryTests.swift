import Foundation
import Testing
@testable import PhotoMemo

@Suite("Batch queue history")
struct BatchQueueHistoryTests {

    @Test("Does not trim terminal history within the retention limit")
    func doesNotTrimTerminalHistoryWithinTheRetentionLimit() {

        let history =
            BatchQueueHistory()
        var jobs =
            (0..<120).map {
                makeTerminalJob(
                    title: "Job \($0)"
                )
            }
        let originalJobs = jobs

        history.trimTerminalJobHistoryIfNeeded(
            &jobs
        )

        #expect(jobs == originalJobs)
    }

    @Test("Trims only the oldest terminal jobs beyond the retention limit")
    func trimsOnlyTheOldestTerminalJobsBeyondTheRetentionLimit() {

        let history =
            BatchQueueHistory()
        var jobs =
            (0..<121).map {
                makeTerminalJob(
                    title: "Job \($0)"
                )
            }

        history.trimTerminalJobHistoryIfNeeded(
            &jobs
        )

        #expect(jobs.count == 120)
        #expect(jobs.map(\.title).first == "Job 0")
        #expect(jobs.map(\.title).last == "Job 119")
    }
}

private extension BatchQueueHistoryTests {

    func makeTerminalJob(
        title: String
    ) -> BatchJob {

        BatchJob(
            title: title,
            state: .completed,
            configuration:
                BatchConfigurationSnapshot(
                    template: .template1,
                    badge: nil,
                    anchor: nil,
                    shouldWritePhotoDescription: true,
                    photoDescriptionOverride: "",
                    selectedAlbumIdentifier: ""
                ),
            tasks: [
                BatchTask(
                    sourceURL:
                        URL(
                            fileURLWithPath:
                                "/tmp/\(title).jpg"
                        ),
                    phase: .completed
                )
            ]
        )
    }
}
