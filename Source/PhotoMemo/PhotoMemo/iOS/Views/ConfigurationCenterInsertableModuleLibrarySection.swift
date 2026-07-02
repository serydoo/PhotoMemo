#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct ConfigurationCenterInsertableModuleLibrarySection: View {

    let visibleModules: [IOSInsertableModule]
    let additionalModules: [IOSInsertableModule]
    let onInsertModule: (IOSInsertableModule) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label(
                    "可插入模块",
                    systemImage: "tag.fill"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

                Spacer(minLength: 0)

                Menu {
                    ForEach(additionalModules) { module in
                        Button {
                            onInsertModule(module)
                        } label: {
                            Label(
                                module.title,
                                systemImage: module.systemImage
                            )
                        }
                    }
                } label: {
                    Label("更多模块", systemImage: "chevron.down.circle")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(visibleModules) { module in
                        Button {
                            onInsertModule(module)
                        } label: {
                            insertableModuleChip(module)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 1)
            }

            Text("默认展示当前最常用的 6 个模块。更多 EXIF 字段可从下拉栏插入；若照片中没有该信息，输出保持为空。")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(9)
        .configurationPanelChrome()
    }

    private func insertableModuleChip(
        _ module: IOSInsertableModule
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: module.systemImage)
                .font(.caption2.weight(.semibold))

            Text(module.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(Color.accentColor)
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.085))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor.opacity(0.16))
        )
    }
}
#endif
