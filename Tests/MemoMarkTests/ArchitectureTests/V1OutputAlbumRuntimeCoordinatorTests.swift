#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("V1 output album runtime coordinator")
struct V1OutputAlbumRuntimeCoordinatorTests {

    @Test("active load publishes loading and its projection")
    @MainActor
    func activeLoadPublishesLoadingAndProjection() async {
        let runtime = OutputAlbumRuntimeCoordinator()
        let context = Self.context()
        let projection = Self.projection(named: "active")
        var updates: [OutputAlbumRuntimeUpdate] = []

        await runtime.load(
            context: context,
            performLoad: { projection },
            currentContext: { context },
            apply: { updates.append($0) }
        )

        #expect(updates == [.loadingStarted, .completed(projection)])
    }

    @Test("newer load rejects an older delayed projection without clearing newer loading")
    @MainActor
    func newerLoadRejectsOlderDelayedProjection() async {
        let runtime = OutputAlbumRuntimeCoordinator()
        let context = Self.context()
        let firstGate = OutputAlbumProjectionGate()
        let firstProjection = Self.projection(named: "first")
        let secondProjection = Self.projection(named: "second")
        var updates: [OutputAlbumRuntimeUpdate] = []

        let firstTask = Task { @MainActor in
            await runtime.load(
                context: context,
                performLoad: { await firstGate.wait() },
                currentContext: { context },
                apply: { updates.append($0) }
            )
        }

        await firstGate.waitUntilSuspended()
        await runtime.load(
            context: context,
            performLoad: { secondProjection },
            currentContext: { context },
            apply: { updates.append($0) }
        )
        firstGate.resume(firstProjection)
        await firstTask.value

        #expect(
            updates
            == [
                .loadingStarted,
                .loadingStarted,
                .completed(secondProjection)
            ]
        )
    }

    @Test("context change rejects its delayed projection and clears loading")
    @MainActor
    func contextChangeRejectsProjectionAndClearsLoading() async {
        let runtime = OutputAlbumRuntimeCoordinator()
        let originalContext = Self.context()
        let changedContext = Self.context(
            selectedAlbumIdentifier: "changed"
        )
        let gate = OutputAlbumProjectionGate()
        var currentContext = originalContext
        var updates: [OutputAlbumRuntimeUpdate] = []

        let task = Task { @MainActor in
            await runtime.load(
                context: originalContext,
                performLoad: { await gate.wait() },
                currentContext: { currentContext },
                apply: { updates.append($0) }
            )
        }

        await gate.waitUntilSuspended()
        currentContext = changedContext
        gate.resume(Self.projection(named: "stale"))
        await task.value

        #expect(updates == [.loadingStarted, .loadingEnded])
    }

    @Test("task cancellation rejects a delayed projection and keeps runtime reusable")
    @MainActor
    func taskCancellationRejectsProjectionAndKeepsRuntimeReusable() async {
        let runtime = OutputAlbumRuntimeCoordinator()
        let context = Self.context()
        let gate = OutputAlbumProjectionGate()
        let nextProjection = Self.projection(named: "next")
        var updates: [OutputAlbumRuntimeUpdate] = []

        let cancelledTask = Task { @MainActor in
            await runtime.load(
                context: context,
                performLoad: { await gate.wait() },
                currentContext: { context },
                apply: { updates.append($0) }
            )
        }

        await gate.waitUntilSuspended()
        cancelledTask.cancel()
        gate.resume(Self.projection(named: "cancelled"))
        await cancelledTask.value

        await runtime.load(
            context: context,
            performLoad: { nextProjection },
            currentContext: { context },
            apply: { updates.append($0) }
        )

        #expect(
            updates
            == [
                .loadingStarted,
                .loadingEnded,
                .loadingStarted,
                .completed(nextProjection)
            ]
        )
    }

    private static func context(
        selectedAlbumIdentifier: String = ""
    ) -> OutputAlbumLoadContext {
        OutputAlbumLoadContext(
            subjectID: UUID(uuidString: "00000000-0000-0000-0000-000000000001"),
            configurationID: UUID(uuidString: "00000000-0000-0000-0000-000000000002"),
            outputTarget: .existingAlbum,
            selectedExistingAlbumIdentifier: selectedAlbumIdentifier
        )
    }

    private static func projection(
        named name: String
    ) -> OutputAlbumLoadProjection {
        OutputAlbumLoadProjection(
            availableAlbums: [
                PhotoAlbumOption(
                    id: name,
                    title: name,
                    localIdentifier: name
                )
            ],
            selectedExistingAlbumIdentifier: name,
            albumStatusMessage: ""
        )
    }
}

@MainActor
private final class OutputAlbumProjectionGate {

    private var continuation:
        CheckedContinuation<OutputAlbumLoadProjection, Never>?

    func wait() async -> OutputAlbumLoadProjection {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func waitUntilSuspended() async {
        while continuation == nil {
            await Task.yield()
        }
    }

    func resume(_ projection: OutputAlbumLoadProjection) {
        continuation?.resume(returning: projection)
        continuation = nil
    }
}
#endif
