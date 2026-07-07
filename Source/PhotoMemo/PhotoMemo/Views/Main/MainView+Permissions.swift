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
                        "用于读取照片，并把生成的新图写回系统图库。",
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
                        "用于在后台处理完成或失败时提醒你。",
                    requestAction:
                        requestNotificationPermission,
                    openSettingsAction:
                        openNotificationSettings
                )
            }

            Text("时光记只会请求完成这条流程所需的本地权限。")
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
                        state == .denied
                            ? "打开系统设置"
                            : "允许访问"
                    ) {
                        if state == .denied {
                            openSettingsAction()
                        } else {
                            requestAction()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            if state == .denied {
                Text("如果已拒绝，请到系统设置里重新开启时光记的权限。")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct MainPermissionSetupSheet: View {

    let dismiss: () -> Void

    let requestInitialPermissions: () -> Void

    var body: some View {

        ZStack {
            MinimalPalette.background
                .ignoresSafeArea()

            VStack {
                VStack(
                    alignment: .leading,
                    spacing: 18
                ) {

                    Text("启用本地权限")
                        .font(.system(
                            size: 26,
                            weight: .semibold
                        ))

                    Text("为了读取照片、保存结果和在处理完成时提醒你，时光记需要相册与通知权限。")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    MinimalInsetCard {
                        permissionPrimerLine(
                            icon: "photo.on.rectangle.angled",
                            title: "系统相册",
                            description:
                                "用于读取照片，并把处理结果写回图库。"
                        )

                        Divider()

                        permissionPrimerLine(
                            icon: "bell.badge",
                            title: "系统通知",
                            description:
                                "用于在处理完成或失败时提醒你。"
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
                .frame(maxWidth: 420, alignment: .leading)
                .background(
                    RoundedRectangle(
                        cornerRadius: 28,
                        style: .continuous
                    )
                    .fill(MinimalPalette.surface)
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: 28,
                        style: .continuous
                    )
                    .stroke(
                        MinimalPalette.border
                    )
                )
                .shadow(
                    color: .black.opacity(0.06),
                    radius: 20,
                    y: 8
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
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
