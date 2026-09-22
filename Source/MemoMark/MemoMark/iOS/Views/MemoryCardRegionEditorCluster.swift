#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import Foundation
import SwiftUI
import UIKit

struct MemoryCardRegionEditorCluster: View {

    @State private var pendingRevealRegion: CardRegion?

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    let presentationStyle: RecordCardPresentationStyle

    let visibleRegions: [CardRegion]

    let photoDescriptionRegions: [CardRegion]

    let slotATextKitCommandBus: MemoryCardTextKitCommandBus
    let slotBTextKitCommandBus: MemoryCardTextKitCommandBus
    let slotCTextKitCommandBus: MemoryCardTextKitCommandBus
    let slotDTextKitCommandBus: MemoryCardTextKitCommandBus

    let draft: (CardRegion) -> MemoryCardEditorDraft
    let onFocus: (CardRegion) -> Void
    let onFocusTextItem: (CardRegion, MemoryCardContentItem) -> Void
    let onFocusTrailingText: (CardRegion) -> Void
    let onUpdateTextItem: (CardRegion, MemoryCardContentItem, String) -> Void
    let onReplaceDraft: (CardRegion, MemoryCardEditorDraft) -> Void
    let onPrependText: (CardRegion, String) -> Void
    let onAppendText: (CardRegion, String) -> Void
    let onRemoveItem: (CardRegion, MemoryCardContentItem) -> Void
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
            if let activeModuleRegion {
                ModuleLibrarySurface(
                    region: activeModuleRegion,
                    modules: modules(activeModuleRegion),
                    categoryTitle: categoryTitle,
                    valueText: valueText,
                    onSelectModule: { module in
                        onSelectModule(module, activeModuleRegion)
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
                .frame(height: ModuleLibrarySurface.height(for: dynamicTypeSize))
                .padding(.horizontal, ConfigurationUI.contentColumnPadding)
                .padding(.top, 8)
                .zIndex(1)
            }

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(visibleRegions, id: \.self) { region in
                                let regionDraft = draft(region)
                                let isSingleRegion = visibleRegions.count == 1

                                if region == .slotA || region == .slotB || region == .slotC || region == .slotD {
                                    let editorTitle: String? = isSingleRegion
                                        ? presentationStyle.contentContract
                                            .editorTitle(
                                                using: .interfaceStored
                                            )
                                        : nil
                                    let editorAccessibilityLabel: String? =
                                        isSingleRegion
                                        ? presentationStyle.contentContract
                                            .editorAccessibilityLabel(
                                                using: .interfaceStored
                                            )
                                        : nil
                                    let editorAccessibilityHint: String? =
                                        isSingleRegion
                                        ? presentationStyle.contentContract
                                            .editorAccessibilityHint(
                                                using: .interfaceStored
                                            )
                                        : nil
                                    let editorTitleColumnWidth = isSingleRegion
                                        ? MemoryCardEditorInputMetrics.titleColumnWidth
                                        : MemoryCardEditorInputMetrics.multiRegionTitleColumnWidth
                                    let editorCommandBus = commandBus(for: region)

                                    MemoryCardTextKitSessionEditor(
                                        region: region,
                                        title: editorTitle,
                                        accessibilityLabel:
                                            editorAccessibilityLabel,
                                        accessibilityHint:
                                            editorAccessibilityHint,
                                        titleColumnWidth: editorTitleColumnWidth,
                                        draft: regionDraft,
                                        commandBus: editorCommandBus,
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
                                MemoryCardRegionEditorCard(
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
                        .padding(10)
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
                .adaptiveScrollContent(
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

    private func reveal(
        _ region: CardRegion,
        using proxy: ScrollViewProxy
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                proxy.scrollTo(region, anchor: .center)
            }
        }
    }

    private func commandBus(
        for region: CardRegion
    ) -> MemoryCardTextKitCommandBus {
        switch region {
        case .slotA:
            return slotATextKitCommandBus
        case .slotB:
            return slotBTextKitCommandBus
        case .slotC:
            return slotCTextKitCommandBus
        case .slotD:
            return slotDTextKitCommandBus
        case .subject,
             .icon,
             .badge:
            assertionFailure("Unexpected TextKit region \(region)")
            return slotATextKitCommandBus
        }
    }

    private var editorFooterNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("这里的内容会怎样使用？")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            guidanceRow(
                number: 1,
                text: "修改会实时出现在上方完整卡片预览中。"
            )
            guidanceRow(
                number: 2,
                text: "处理照片时，模块会替换为每张照片自己的信息。"
            )
            if !photoDescriptionRegions.isEmpty {
                guidanceRow(
                    number: 3,
                    text: "这里的内容还会写入 Apple Photos 的照片说明，方便之后查找。"
                )
            }

        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func guidanceRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                )

            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }
}
#endif
