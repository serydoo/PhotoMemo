import Foundation

extension MainView {

    func openPhotoLibrarySettings() {

        permissionCenter
            .openSystemSettings(
                for: .photoLibrary
            )
    }

    func requestPhotoLibraryPermissionAction() {

        Task {
            await requestPhotoLibraryPermission()
        }
    }

    func saveCurrentCardToAlbumAction() {

        Task {
            await saveCurrentCardToAlbum()
        }
    }

    var selectedAlbumLocalIdentifier: String? {

        selectedAlbumIdentifier
            == PhotoAlbumOption.automaticIdentifier
            ? nil
            : selectedAlbumIdentifier
    }

    func requestPhotoLibraryPermission() async {

        let granted =
            await permissionCenter
            .requestPhotoLibraryPermission()

        if granted {
            await reloadAlbums()
            return
        }

        if permissionCenter.photoLibraryState
            == .denied {
            presentAlert(
                title: "请到系统设置开启相册权限",
                message: "macOS 在你拒绝后不会再次自动弹出相册授权框。请点击权限区里的“打开系统设置”，然后为 PhotoMemo 重新开启相册权限。"
            )
            return
        }

        presentAlert(
            title: "需要相册权限",
            message: "请允许 PhotoMemo 访问系统相册，这样才能读取照片并把处理后的图片存回图库。"
        )
    }

    func reloadAlbums(
        presentAlerts: Bool = true
    ) async {

        await permissionCenter.refreshStatuses()

        guard permissionCenter.canAccessPhotoLibrary else {
            availableAlbums = []

            guard presentAlerts else {
                return
            }

            if permissionCenter.photoLibraryState
                == .notDetermined {
                await requestPhotoLibraryPermission()
            } else {
                presentAlert(
                    title: "需要相册权限",
                    message: "请先允许 PhotoMemo 访问系统相册，之后才能读取相册列表和保存处理结果。"
                )
            }
            return
        }

        do {

            availableAlbums =
                try await photoLibraryExportService
                .fetchAlbumOptions()

            if selectedAlbumIdentifier
                != PhotoAlbumOption.automaticIdentifier,
               selectedAlbumIdentifier
                != PhotoMemoAlbumSelection
                .systemLibraryIdentifier,
               !availableAlbums.contains(
                where: {
                    $0.id == selectedAlbumIdentifier
                }
               ) {

                selectedAlbumIdentifier =
                    PhotoAlbumOption
                    .automaticIdentifier
            }

            persistEditorDraftState(
                selectedAlbumIdentifier:
                    settings.normalizedAlbumIdentifier(
                        selectedAlbumIdentifier
                    ),
                selectedAlbumTitle:
                    resolvedAlbumTitle(
                        for: selectedAlbumIdentifier
                    ) ?? "",
                immediately: true
            )

        } catch {

            if presentAlerts {
                presentAlert(
                    title: "无法读取相册",
                    message:
                    (error as? LocalizedError)?
                    .errorDescription
                    ?? error.localizedDescription
                )
            }
        }
    }

    func saveCurrentCardToAlbum() async {

        guard
            let selectedPhoto,
            let currentCard
        else {
            return
        }

        await permissionCenter.refreshStatuses()

        if !permissionCenter.canAccessPhotoLibrary {
            await requestPhotoLibraryPermission()
            guard permissionCenter.canAccessPhotoLibrary else {
                return
            }
        }

        isSavingToAlbum = true

        defer {
            isSavingToAlbum = false
        }

        var temporaryURL: URL?

        do {

            let url =
                try exportService.exportToTemporaryFile(
                    photo: selectedPhoto,
                    card: currentCard
                )

            temporaryURL = url

            let albumName =
                try await photoLibraryExportService
                .saveImage(
                    at: url,
                    metadata: selectedPhoto.metadata,
                    preferredAlbumIdentifier:
                        selectedAlbumLocalIdentifier
                )

            try? FileManager.default.removeItem(
                at: url
            )

            presentAlert(
                title: "已存入系统相册",
                message:
                    albumName
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty
                    ? "图片已经写入系统图库，拍摄时间与原图元数据会尽量保持一致。"
                    : "图片已经写入系统图库“\(albumName)”中，拍摄时间与原图元数据会尽量保持一致。"
            )

            presentSaveFeedback(
                title:
                    albumName
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty
                    ? "已写入系统图库"
                    : "已存入“\(albumName)”",
                message: "新图已经写回系统图库，预览正确的话可以继续处理下一张。"
            )

            await reloadAlbums(
                presentAlerts: false
            )

        } catch {

            if let temporaryURL {
                try? FileManager.default.removeItem(
                    at: temporaryURL
                )
            }

            presentAlert(
                title: "存入相册失败",
                message:
                    (error as? LocalizedError)?
                    .errorDescription
                    ?? error.localizedDescription
            )
        }
    }
}
