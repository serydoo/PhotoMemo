#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import SwiftUI
import UIKit

struct V1RegionEditorCluster: View {

    @State private var pendingRevealRegion: CardRegion?

    let visibleRegions: [CardRegion]

    let slotATextKitCommandBus: V1TextKitCommandBus
    let slotBTextKitCommandBus: V1TextKitCommandBus
    let slotCTextKitCommandBus: V1TextKitCommandBus
    let slotDTextKitCommandBus: V1TextKitCommandBus

    let draft: (CardRegion) -> V1EditorDraft
    let onFocus: (CardRegion) -> Void
    let onFocusTextItem: (CardRegion, V1ContentItem) -> Void
    let onFocusTrailingText: (CardRegion) -> Void
    let onUpdateTextItem: (CardRegion, V1ContentItem, String) -> Void
    let onReplaceDraft: (CardRegion, V1EditorDraft) -> Void
    let onPrependText: (CardRegion, String) -> Void
    let onAppendText: (CardRegion, String) -> Void
    let onRemoveItem: (CardRegion, V1ContentItem) -> Void
    let onRemovePreviousComposedItem: (CardRegion, UUID) -> Bool
    let focusedRegion: CardRegion?
    let activeModuleRegion: CardRegion?
    let modules: (CardRegion) -> [IOSInsertableModule]
    let categoryTitle: (IOSInsertableModule) -> String
    let valueText: (IOSInsertableModule) -> String
    let insertionMarkerID: (CardRegion) -> UUID?
    let showsInsertionMarkerAtEnd: (CardRegion) -> Bool
    let onSelectModule: (IOSInsertableModule, CardRegion) -> Void
    let onCloseModuleLibrary: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            currentEditingTask

            if let activeModuleRegion {
                V1ModuleLibrarySurface(
                    region: activeModuleRegion,
                    modules: modules(activeModuleRegion),
                    categoryTitle: categoryTitle,
                    valueText: valueText,
                    onSelectModule: { module in
                        onSelectModule(module, activeModuleRegion)
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
                .frame(height: V1ModuleLibrarySurface.fixedHeight)
                .padding(.horizontal, ConfigurationUI.contentColumnPadding)
                .padding(.top, 8)
                .zIndex(1)
            }

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(visibleRegions, id: \.self) { region in
                                let regionDraft = draft(region)

                                if region == .slotA || region == .slotB || region == .slotC || region == .slotD {
                                    V1SlotATextKitSessionEditor(
                                        region: region,
                                        title:
                                            visibleRegions.count == 1
                                            ? localized("输出内容")
                                            : nil,
                                        draft: regionDraft,
                                        commandBus: region == .slotA
                                            ? slotATextKitCommandBus
                                            : region == .slotB
                                                ? slotBTextKitCommandBus
                                                : region == .slotC
                                                    ? slotCTextKitCommandBus
                                                    : slotDTextKitCommandBus,
                                        isFocused: focusedRegion == region,
                                        onFocus: {
                                            pendingRevealRegion = region
                                            onFocus(region)
                                            reveal(region, using: proxy)
                                        },
                                        onDraftChange: { updatedDraft in
                                            onReplaceDraft(region, updatedDraft)
                                        }
                                    )
                                    .id(region)
                                } else {
                                V1RegionEditorCard(
                                    region: region,
                                    showsDivider:
                                        region != CardRegion.memoryCardRegions.last,
                                    draft: regionDraft,
                                    onFocus: {
                                        pendingRevealRegion = region
                                        onFocus(region)
                                        reveal(region, using: proxy)
                                    },
                                    onFocusTextItem: { item in
                                        pendingRevealRegion = region
                                        onFocusTextItem(region, item)
                                        reveal(region, using: proxy)
                                    },
                                    onFocusTrailingText: {
                                        pendingRevealRegion = region
                                        onFocusTrailingText(region)
                                        reveal(region, using: proxy)
                                    },
                                    onUpdateTextItem: { item, text in
                                        onUpdateTextItem(region, item, text)
                                    },
                                    onPrependText: { text in
                                        onPrependText(region, text)
                                    },
                                    onAppendText: { text in
                                        onAppendText(region, text)
                                    },
                                    onRemoveItem: { item in
                                        onRemoveItem(region, item)
                                    },
                                    onRemovePreviousComposedItem: { itemID in
                                        onRemovePreviousComposedItem(region, itemID)
                                    },
                                    insertionMarkerID: insertionMarkerID(region),
                                    showsInsertionMarkerAtEnd:
                                        showsInsertionMarkerAtEnd(region)
                                )
                                .id(region)
                                }
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(
                                cornerRadius: ConfigurationUI.cardCornerRadius,
                                style: .continuous
                            )
                            .fill(ConfigurationUI.panelBackground)
                        )
                        .overlay(
                            RoundedRectangle(
                                cornerRadius: ConfigurationUI.cardCornerRadius,
                                style: .continuous
                            )
                            .stroke(ConfigurationUI.faintHairline)
                        )

                        editorFooterNote
                    }
                    .padding(.top, 12)
                }
                .padding(.bottom, 28)
                .v1AdaptiveScrollContent(
                    horizontalPadding: ConfigurationUI.contentColumnPadding
                )
                .scrollDismissesKeyboard(.never)
                .frame(maxHeight: .infinity)
                .onChange(of: focusedRegion) { _, region in
                    guard let region else { return }
                    reveal(region, using: proxy)
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIResponder.keyboardWillChangeFrameNotification
                    )
                ) { _ in
                    guard let region = pendingRevealRegion else {
                        return
                    }
                    reveal(region, using: proxy)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .clipped()
    }

    private var activeRegion: CardRegion {
        let candidate = focusedRegion ?? activeModuleRegion ?? .slotA
        return visibleRegions.contains(candidate)
            ? candidate
            : visibleRegions.first ?? .slotA
    }

    private var currentEditingTask: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(
                    visibleRegions.count == 1
                    ? localized("正在编辑输出内容")
                    : "正在编辑\(activeRegion.displayTitle)"
                )
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(
                    visibleRegions.count == 1
                    ? localized("这里的组合内容会显示在照片底部的极简条中。")
                    : "这里的内容会显示在照片卡片\(activeRegion.displayTitle)方。"
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if visibleRegions.count > 1 {
                V1CardRegionNavigator(
                    selectedRegion: activeRegion,
                    onSelect: { region in
                        pendingRevealRegion = region
                        onFocus(region)
                        commandBus(for: region)?.requestFocus()
                    }
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.cardCornerRadius,
                style: .continuous
            )
            .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.cardCornerRadius,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
        .padding(.horizontal, ConfigurationUI.contentColumnPadding)
        .padding(.top, 2)
        .padding(.bottom, 8)
        .accessibilityElement(children: .contain)
    }

    private func reveal(
        _ region: CardRegion,
        using proxy: ScrollViewProxy
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(region, anchor: .center)
            }
        }
    }

    private func commandBus(for region: CardRegion) -> V1TextKitCommandBus? {
        switch region {
        case .slotA:
            slotATextKitCommandBus
        case .slotB:
            slotBTextKitCommandBus
        case .slotC:
            slotCTextKitCommandBus
        case .slotD:
            slotDTextKitCommandBus
        default:
            nil
        }
    }

    private func localized(_ value: String) -> String {
        MemoMarkLanguage.interfaceStored.localized(
            key: value,
            fallback: value
        )
    }

    private var editorFooterNote: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("这里的内容会怎样使用？")
                .font(.headline)
                .foregroundStyle(.primary)

            guidanceRow(
                number: 1,
                text: "修改会实时出现在上方完整卡片预览中。"
            )
            guidanceRow(
                number: 2,
                text: "处理照片时，模块会替换为每张照片自己的信息。"
            )
            if visibleRegions.count > 1 {
                guidanceRow(
                    number: 3,
                    text: "右下内容还会写入 Apple Photos 的照片说明，方便之后查找。"
                )
            }

            Text("点“完成”返回配置中心；收起键盘不会离开编辑页。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 1)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.cardCornerRadius,
                style: .continuous
            )
            .fill(ConfigurationUI.panelBackground)
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.cardCornerRadius,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    private func guidanceRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                )

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }
}

private struct V1CardRegionNavigator: View {

    let selectedRegion: CardRegion
    let onSelect: (CardRegion) -> Void

    var body: some View {
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(CardRegion.memoryCardRegions, id: \.self) { region in
                regionButton(region)
            }
        }
        .padding(5)
        .frame(width: 86, height: 58)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.08))
        )
        .sensoryFeedback(.selection, trigger: selectedRegion)
        .accessibilityLabel("卡片区域")
    }

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 5),
            GridItem(.flexible(), spacing: 5)
        ]
    }

    private func regionButton(_ region: CardRegion) -> some View {
        let isSelected = region == selectedRegion

        return Button {
            onSelect(region)
        } label: {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(
                    isSelected
                    ? Color.accentColor.opacity(0.18)
                    : Color.primary.opacity(0.045)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(
                            isSelected
                            ? Color.accentColor.opacity(0.52)
                            : Color.primary.opacity(0.055),
                            lineWidth: isSelected ? 1.2 : 0.8
                        )
                )
                .overlay {
                    Circle()
                        .fill(
                            isSelected
                            ? Color.accentColor
                            : Color.secondary.opacity(0.42)
                        )
                        .frame(width: isSelected ? 5 : 3, height: isSelected ? 5 : 3)
                }
                .scaleEffect(isSelected ? 1.08 : 0.94)
                .shadow(
                    color: isSelected
                    ? Color.accentColor.opacity(0.16)
                    : .clear,
                    radius: 4,
                    y: 2
                )
                .animation(
                    .spring(response: 0.28, dampingFraction: 0.82),
                    value: isSelected
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(region.displayTitle)
        .accessibilityValue(isSelected ? "正在编辑" : "未选择")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
#endif
