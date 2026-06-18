import SwiftUI

struct MainPermissionSection: View {

    let photoLibraryState: PermissionState

    let notificationState: PermissionState

    let requestPhotoLibraryPermission: () -> Void

    let openPhotoLibrarySettings: () -> Void

    let requestNotificationPermission: () -> Void

    let openNotificationSettings: () -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            MinimalInsetCard {
                permissionRow(
                    title: "系统相册",
                    icon: "photo.on.rectangle.angled",
                    state: photoLibraryState,
                    description:
                        "用于读取你选择的照片，并把处理后的新图直接写回系统图库。",
                    requestAction:
                        requestPhotoLibraryPermission,
                    openSettingsAction:
                        openPhotoLibrarySettings
                )

                Divider()

                permissionRow(
                    title: "系统通知",
                    icon: "bell.badge",
                    state: notificationState,
                    description:
                        "用于在后台处理开始、完成或失败时给你明确反馈。",
                    requestAction:
                        requestNotificationPermission,
                    openSettingsAction:
                        openNotificationSettings
                )
            }

            Text(
                "PhotoMemo 完全本地运行，不依赖联网；这里只会请求相册与通知两项必要能力。"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    @ViewBuilder
    private func permissionRow(
        title: String,
        icon: String,
        state: PermissionState,
        description: String,
        requestAction: @escaping () -> Void,
        openSettingsAction: @escaping () -> Void
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            HStack(
                alignment: .top,
                spacing: 12
            ) {

                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(
                        MinimalPalette.accent
                    )
                    .frame(width: 24)

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    HStack(spacing: 8) {
                        Text(title)
                            .font(.subheadline.weight(.medium))

                        Text(state.statusText)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(
                                state.isGranted
                                ? Color.green
                                : Color.secondary
                            )
                    }

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {

                if state.isGranted {

                    Label(
                        "已就绪",
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.green)

                } else {

                    Button(
                        state == .notDetermined
                            ? "允许访问"
                            : "重新授权"
                    ) {
                        requestAction()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                if state == .denied {

                    Button("打开系统设置") {
                        openSettingsAction()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }
}

struct MainPermissionSetupSheet: View {

    let dismiss: () -> Void

    let requestInitialPermissions: () -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            Text("启用本地权限")
                .font(.system(
                    size: 26,
                    weight: .semibold
                ))

            Text("PhotoMemo 完全本地运行，不需要联网。为了读取照片 EXIF、把处理后的图片存回系统图库，以及在后台任务完成时提醒你，需要先允许相册和通知权限。")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            MinimalInsetCard {
                permissionPrimerLine(
                    icon: "photo.on.rectangle.angled",
                    title: "系统相册",
                    description:
                        "用于读取你挑选的照片，并把处理结果写回图库或指定相册。"
                )

                Divider()

                permissionPrimerLine(
                    icon: "bell.badge",
                    title: "系统通知",
                    description:
                        "用于在后台处理开始、完成或失败时提醒你。"
                )
            }

            HStack(spacing: 10) {
                Button("稍后再说") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("现在授权") {
                    requestInitialPermissions()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(
            minWidth: 460,
            idealWidth: 520
        )
        .background(
            MinimalPalette.background
        )
    }

    @ViewBuilder
    private func permissionPrimerLine(
        icon: String,
        title: String,
        description: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(
                    MinimalPalette.accent
                )
                .frame(width: 24)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(title)
                    .font(.subheadline.weight(.medium))

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
