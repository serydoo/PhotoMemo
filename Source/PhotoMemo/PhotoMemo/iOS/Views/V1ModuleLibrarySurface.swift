#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import UIKit

struct V1ModuleLibrarySurface: View {

    static let fixedHeight: CGFloat = 84

    let region: CardRegion
    let modules: [IOSInsertableModule]
    let categoryTitle: (IOSInsertableModule) -> String
    let valueText: (IOSInsertableModule) -> String
    let onSelectModule: (IOSInsertableModule) -> Void

    private var groupedModules: [ModuleGroup] {
        let categoryTitles = modules.reduce(into: [String]()) {
            titles, module in
            let title = categoryTitle(module)
            if !titles.contains(title) {
                titles.append(title)
            }
        }

        return categoryTitles.map { title in
            ModuleGroup(
                title: title,
                modules: modules.filter {
                    categoryTitle($0) == title
                }
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(groupedModules) { group in
                    HStack(alignment: .center, spacing: 8) {
                        Text(group.title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 48, alignment: .leading)
                            .lineLimit(1)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(group.modules) { module in
                                    moduleButton(module)
                                }
                            }
                        }
                        .frame(height: 30, alignment: .top)
                        .overlay(alignment: .trailing) {
                            if group.modules.count > 4 {
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        Color(uiColor: .secondarySystemGroupedBackground)
                                            .opacity(0.92)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: 16)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                            }
                        }
                        .overlay(alignment: .bottom) {
                            if group.modules.count > 4 {
                                Capsule(style: .continuous)
                                    .fill(Color.accentColor.opacity(0.38))
                                    .frame(width: 34, height: 2)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(height: Self.fixedHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.sheetPanelCornerRadius,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.sheetPanelCornerRadius,
                style: .continuous
            )
            .stroke(Color.primary.opacity(0.08))
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(region.semanticTitle)的模块候选")
    }

    private func moduleButton(
        _ module: IOSInsertableModule
    ) -> some View {
        Button {
            UISelectionFeedbackGenerator()
                .selectionChanged()
            onSelectModule(module)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: module.systemImage)
                    .font(.caption2.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)

                Text(module.title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 8)
            .frame(height: 29)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(0.10))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.accentColor.opacity(0.18))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "插入\(module.title)，当前值\(valueText(module))"
        )
    }
}

private extension V1ModuleLibrarySurface {

    struct ModuleGroup: Identifiable {
        let title: String
        let modules: [IOSInsertableModule]

        var id: String {
            title
        }
    }
}
#endif
