#if os(iOS)
import SwiftUI

struct MemoMarkiOSHomeView: View {

    @Environment(\.scenePhase)
    private var scenePhase

    @State
    private var showsBackgroundStatusSheet =
        false

    @ObservedObject
    var runtime: MemoMarkAppRuntime

    @ObservedObject
    private var batchQueueStore:
        BatchQueueStore

    @ObservedObject
    private var backgroundStatusService:
        MemoMarkBackgroundStatusService

    @ObservedObject
    private var permissionCenter:
        PermissionCenter

    private let backgroundExecutionService:
        MemoMarkiOSBackgroundExecutionService

    init(
        runtime: MemoMarkAppRuntime
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
        self._permissionCenter =
            ObservedObject(
                wrappedValue:
                    runtime.permissionCenter
            )
        self.backgroundExecutionService =
            runtime
            .backgroundExecutionService
    }

    var body: some View {

        MemoMarkRootSceneView(
            runtime: runtime
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
            MemoMarkiOSBackgroundStatusSheet(
                backgroundStatusService:
                    backgroundStatusService,
                batchQueueStore:
                    batchQueueStore,
                permissionCenter:
                    runtime.permissionCenter,
                authorizePhotoWorkflow: {
                    await runtime
                        .authorizePhotoWorkflow()
                },
                authorizeNotificationWorkflow: {
                    await runtime
                        .authorizeNotificationWorkflow()
                }
            )
        }
        .task {
            await permissionCenter.refreshStatuses()
            guard permissionCenter.shouldPresentPrimer else {
                return
            }
            permissionCenter.markPrimerPresented()
            showsBackgroundStatusSheet = true
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
