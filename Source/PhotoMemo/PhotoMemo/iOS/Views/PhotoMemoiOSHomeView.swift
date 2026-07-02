#if os(iOS)
import SwiftUI

struct PhotoMemoiOSHomeView: View {

    @Environment(\.scenePhase)
    private var scenePhase

    @State
    private var showsBackgroundStatusSheet =
        false

    @ObservedObject
    var runtime: PhotoMemoAppRuntime

    @ObservedObject
    private var batchQueueStore:
        BatchQueueStore

    @ObservedObject
    private var backgroundStatusService:
        PhotoMemoBackgroundStatusService

    private let backgroundExecutionService:
        PhotoMemoiOSBackgroundExecutionService

    private let temporaryEntryConfiguration:
        PhotoMemoiOSTemporaryEntryConfiguration

    init(
        runtime: PhotoMemoAppRuntime,
        temporaryEntryConfiguration:
            PhotoMemoiOSTemporaryEntryConfiguration = .standard
    ) {
        self.runtime = runtime
        self._batchQueueStore =
            ObservedObject(
                wrappedValue:
                    runtime.batchQueueStore
            )
        self._backgroundStatusService =
            ObservedObject(
                wrappedValue:
                    runtime
                    .backgroundStatusService
            )
        self.backgroundExecutionService =
            runtime
            .backgroundExecutionService
        self.temporaryEntryConfiguration =
            temporaryEntryConfiguration
    }

    var body: some View {

        PhotoMemoRootSceneView(
            runtime: runtime,
            temporaryEntryConfiguration:
                temporaryEntryConfiguration
        )
        .toolbar {
            ToolbarItem(
                placement: .topBarTrailing
            ) {
                Button {
                    showsBackgroundStatusSheet = true
                } label: {
                    Image(
                        systemName:
                            backgroundStatusSymbolName
                    )
                }
                .accessibilityLabel("后台状态")
            }
        }
        .sheet(
            isPresented:
                $showsBackgroundStatusSheet
        ) {
            PhotoMemoiOSBackgroundStatusSheet(
                backgroundStatusService:
                    backgroundStatusService,
                batchQueueStore:
                    batchQueueStore
            )
        }
        .onAppear {
            backgroundExecutionService
                .scenePhaseDidChange(
                    scenePhase
                )
        }
        .onChange(of: scenePhase) {
            _, newPhase in

            backgroundExecutionService
                .scenePhaseDidChange(
                    newPhase
                )
        }
    }

    private var backgroundStatusSymbolName: String {

        guard let snapshot =
            backgroundStatusService
            .currentSnapshot
        else {
            return "square.stack.3d.down.forward"
        }

        switch snapshot
            .presentationState {

        case .active:
            return "arrow.trianglehead.2.clockwise.circle.fill"

        case .needsAttention:
            return "exclamationmark.triangle.fill"

        case .completed:
            return "checkmark.circle.fill"
        }
    }
}
#endif
