import Foundation

extension MainView {

    func openNotificationSettings() {

        permissionCenter
            .openSystemSettings(
                for: .notifications
            )
    }

    func requestInitialPermissionsAction() {

        Task {
            await requestInitialPermissions()
        }
    }

    func requestNotificationPermissionAction() {

        Task {
            await requestNotificationPermission()
        }
    }

    func preparePermissionsOnAppear() async {

        await permissionCenter.refreshStatuses()

        if permissionCenter.shouldPresentPrimer {
            permissionCenter.markPrimerPresented()
            presentationState
                .showsPermissionSetupSheet = true
        }

        if permissionCenter.canAccessPhotoLibrary {
            await reloadAlbums()
        } else {
            availableAlbums = []
        }
    }

    func refreshPermissionsForActiveScene() async {

        let couldAccessBefore =
            permissionCenter.canAccessPhotoLibrary

        await permissionCenter.refreshStatuses()

        if permissionCenter.canAccessPhotoLibrary {
            if !couldAccessBefore
                || availableAlbums.isEmpty {
                await reloadAlbums()
            }
        } else {
            availableAlbums = []
        }
    }

    func requestInitialPermissions() async {

        _ = await permissionCenter
            .requestPhotoLibraryPermission()
        _ = await permissionCenter
            .requestNotificationPermission()

        presentationState
            .showsPermissionSetupSheet = false

        if permissionCenter.canAccessPhotoLibrary {
            await reloadAlbums()
        }
    }

    func requestNotificationPermission() async {

        let granted =
            await permissionCenter
            .requestNotificationPermission()

        guard !granted else {
            return
        }

        presentAlert(
            title: "通知尚未开启",
            message: "你仍然可以继续使用 PhotoMemo，只是后台处理完成时不会自动弹出系统通知。"
        )
    }
}
