#if os(iOS)
import BackgroundTasks
import Foundation
import Photos

enum PhotoMemoBackgroundTaskSubmission {
    static let taskIdentifier =
        "com.serydoo.PhotoMemo.batch-processing"

    static var requiresHostAppForPhotoAuthorization: Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized,
             .limited:
            return false
        case .notDetermined,
             .restricted,
             .denied:
            return true
        @unknown default:
            return true
        }
    }

    static func submit() -> Bool {
        let request = BGProcessingTaskRequest(
            identifier: taskIdentifier
        )
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(
            timeIntervalSinceNow: 1
        )
        do {
            try BGTaskScheduler.shared.submit(request)
#if PHOTOMEMO_SHARE_EXTENSION
            PhotoMemoShareDiagnostics.record(
                stage: .extensionHandoffRequested,
                message:
                    "Background processing request submitted."
            )
#endif
            return true
        } catch {
#if PHOTOMEMO_SHARE_EXTENSION
            let diagnosticStage:
                PhotoMemoShareDiagnosticStage =
                    .extensionHandoffUnconfirmed
#else
            let diagnosticStage:
                PhotoMemoShareDiagnosticStage =
                    .appEnqueueFailed
#endif
            PhotoMemoShareDiagnostics.record(
                stage: diagnosticStage,
                message:
                    "Background processing request failed: \(error.localizedDescription)"
            )
            return false
        }
    }
}
#endif
