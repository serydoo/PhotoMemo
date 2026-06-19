import Foundation
import Combine
import Photos
import UserNotifications
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

enum PermissionDomain: Hashable {

    case photoLibrary

    case notifications
}

enum PermissionState: Hashable {

    case notDetermined

    case authorized

    case limited

    case denied
}

extension PermissionState {

    var isGranted: Bool {

        switch self {

        case .authorized,
             .limited:
            return true

        case .notDetermined,
             .denied:
            return false
        }
    }

    var statusText: String {

        switch self {

        case .notDetermined:
            return "尚未授权"

        case .authorized:
            return "已允许"

        case .limited:
            return "部分允许"

        case .denied:
            return "已关闭"
        }
    }
}

@MainActor
final class PermissionCenter:
    ObservableObject {

    private let defaults =
        PhotoMemoSharedContainer
        .sharedUserDefaults

    private enum Keys {

        static let didPresentPrimer =
            "photomemo.permissions.didPresentPrimer"
    }

    @Published private(set)
    var photoLibraryState:
        PermissionState = .notDetermined

    @Published private(set)
    var notificationState:
        PermissionState = .notDetermined

    var canAccessPhotoLibrary: Bool {
        photoLibraryState.isGranted
    }

    var canDeliverNotifications: Bool {
        notificationState.isGranted
    }

    var shouldPresentPrimer: Bool {

        let didPresent =
            defaults.bool(
                forKey: Keys.didPresentPrimer
            )

        guard !didPresent else {
            return false
        }

        return photoLibraryState == .notDetermined
            || notificationState == .notDetermined
    }

    func markPrimerPresented() {

        defaults.set(
            true,
            forKey: Keys.didPresentPrimer
        )
    }

    func refreshStatuses() async {

        photoLibraryState =
            resolvedPhotoLibraryState()
        notificationState =
            await resolvedNotificationState()
    }

    @discardableResult
    func requestPhotoLibraryPermission() async -> Bool {

        let status =
            PHPhotoLibrary.authorizationStatus(
                for: .readWrite
            )

        let nextStatus: PHAuthorizationStatus

        if status == .notDetermined {
            nextStatus =
                await withCheckedContinuation {
                    continuation in

                    PHPhotoLibrary.requestAuthorization(
                        for: .readWrite
                    ) { resolvedStatus in

                        continuation.resume(
                            returning: resolvedStatus
                        )
                    }
                }
        } else {
            nextStatus = status
        }

        photoLibraryState =
            Self.mapPhotoState(
                nextStatus
            )

        return photoLibraryState.isGranted
    }

    @discardableResult
    func requestNotificationPermission() async -> Bool {

        let center =
            UNUserNotificationCenter.current()

        let settings =
            await center.notificationSettings()

        switch settings.authorizationStatus {

        case .authorized,
             .provisional,
             .ephemeral:
            notificationState = .authorized
            return true

        case .notDetermined:
            do {
                let granted =
                    try await center
                    .requestAuthorization(
                        options: [
                            .alert,
                            .sound,
                            .badge
                        ]
                    )

                notificationState =
                    granted
                    ? .authorized
                    : .denied
                return granted
            } catch {
                notificationState = .denied
                return false
            }

        case .denied:
            notificationState = .denied
            return false

        @unknown default:
            notificationState = .denied
            return false
        }
    }

    func openSystemSettings(
        for domain: PermissionDomain
    ) {

#if os(macOS)
        let urlString: String

        switch domain {

        case .photoLibrary:
            urlString =
                "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos"

        case .notifications:
            urlString =
                "x-apple.systempreferences:com.apple.preference.notifications"
        }

        guard let url =
            URL(string: urlString)
        else {
            return
        }

        NSWorkspace.shared.open(url)
#elseif canImport(UIKit) && PHOTOMEMO_SHARE_EXTENSION
        return
#elseif canImport(UIKit)
        guard let url =
            URL(string: UIApplication.openSettingsURLString)
        else {
            return
        }

        UIApplication.shared.open(url)
#endif
    }
}

private extension PermissionCenter {

    func resolvedPhotoLibraryState() -> PermissionState {

        Self.mapPhotoState(
            PHPhotoLibrary.authorizationStatus(
                for: .readWrite
            )
        )
    }

    func resolvedNotificationState() async
        -> PermissionState {

        let settings =
            await UNUserNotificationCenter
            .current()
            .notificationSettings()

        switch settings.authorizationStatus {

        case .authorized,
             .provisional,
             .ephemeral:
            return .authorized

        case .notDetermined:
            return .notDetermined

        case .denied:
            return .denied

        @unknown default:
            return .denied
        }
    }

    static func mapPhotoState(
        _ status: PHAuthorizationStatus
    ) -> PermissionState {

        switch status {

        case .authorized:
            return .authorized

        case .limited:
            return .limited

        case .notDetermined:
            return .notDetermined

        case .denied,
             .restricted:
            return .denied

        @unknown default:
            return .denied
        }
    }
}
