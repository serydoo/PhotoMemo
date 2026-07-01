#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import PhotosUI
import SwiftUI
import UIKit

struct V1AccessoryEntrySection: View {

    @Binding var logoMode: V1LogoMode
    @Binding var selectedLogoItem: PhotosPickerItem?
    @Binding var birthdayDate: Date
    let logoStatusMessage: String
    let logoRowDetail: String
    let subjectAvatarLogoImagePath: String?
    let subjectAvatarPreviewImagePath: String?
    let customLogoImagePath: String?
    let isOptimizingLogo: Bool
    let timeAnchorTitle: String
    let smartTimeValue: String
    let birthdaySummaryText: String
    let logoExpanded: Binding<Bool>
    let anchorExpanded: Binding<Bool>

    var body: some View {
        IOSCompactEntryListGroup {
            IOSCompactEntryDisclosureRow(
                title: "Logo 标识",
                subtitle: "Apple 标识 / 自选标识 / 使用对象头像",
                value: logoMode.title,
                detail: logoRowDetail,
                systemImage: "seal.fill",
                isExpanded: logoExpanded
            ) {
                logoEditorContent
            }

            IOSCompactEntryDisclosureRow(
                title: "时间锚点",
                subtitle: timeAnchorTitle,
                value: smartTimeValue,
                detail: birthdaySummaryText,
                systemImage: "calendar.badge.clock",
                showsDivider: false,
                isExpanded: anchorExpanded
            ) {
                anchorEditorContent
            }
        }
    }

    private var logoEditorContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Logo 标识", selection: $logoMode) {
                ForEach(V1LogoMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            HStack(alignment: .center, spacing: 12) {
                logoPreview

                VStack(alignment: .leading, spacing: 3) {
                    Text("当前状态")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(logoMode.title)
                        .font(.subheadline.weight(.semibold))

                    Text(logoStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                Spacer(minLength: 0)
            }

            if logoMode == .customUpload {
                PhotosPicker(
                    selection: $selectedLogoItem,
                    matching: .images
                ) {
                    Label(
                        isOptimizingLogo
                        ? "正在优化"
                        : "选择 Logo",
                        systemImage:
                            isOptimizingLogo
                            ? "hourglass"
                            : "photo.badge.plus"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(isOptimizingLogo)
            } else if logoMode == .subjectAvatar {
                Text("对象头像来自当前记忆对象配置，会自动按头像、标识和预览三种用途准备资源。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
        }
    }

    private var anchorEditorContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            DatePicker(
                "途途生日",
                selection: $birthdayDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 3) {
                    Text("时间结果")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(smartTimeValue)
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
    }

    private var logoPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(width: 74, height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            style: StrokeStyle(
                                lineWidth: 1,
                                dash: [5, 4]
                            )
                        )
                        .foregroundStyle(
                            Color.black.opacity(0.10)
                        )
                )

            switch logoMode {
            case .appleMini:
                Image(systemName: "apple.logo")
                    .font(.title2.weight(.semibold))
            case .customUpload:
                if let customLogoImagePath,
                   let image = UIImage(
                    contentsOfFile: customLogoImagePath
                   ) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title3.weight(.semibold))
                        Text("上传")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                }
            case .subjectAvatar:
                if let subjectAvatarPreviewImagePath,
                   let image = UIImage(
                    contentsOfFile:
                        subjectAvatarPreviewImagePath
                   ) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 38, height: 38)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.title3.weight(.semibold))
                        Text("头像")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
}
#endif
