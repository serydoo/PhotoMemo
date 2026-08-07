#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import SwiftUI
import UIKit

struct V1RegionEditorCluster: View {

    @State private var pendingRevealRegion: CardRegion?

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
                    VStack(alignment: .leading, spacing: 12) {
                        IOSCompactEntryListGroup(
                            cornerRadius: ConfigurationUI.sheetPanelCornerRadius
                        ) {
                            ForEach(CardRegion.memoryCardRegions, id: \.self) { region in
                                let regionDraft = draft(region)

                                if region == .slotA || region == .slotB || region == .slotC || region == .slotD {
                                    V1SlotATextKitSessionEditor(
                                        region: region,
                                        draft: regionDraft,
                                        commandBus: region == .slotA
                                            ? slotATextKitCommandBus
                                            : region == .slotB
                                                ? slotBTextKitCommandBus
                                                : region == .slotC
                                                    ? slotCTextKitCommandBus
                                                    : slotDTextKitCommandBus,
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
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(region, anchor: .center)
            }
        }
    }

    private var editorFooterNote: some View {
        Text("四个卡片区域都可以自由组合文字和内容，修改会实时同步到上方预览；卡片右下会写入照片说明。点“完成”后统一保存，收起键盘不会离开编辑页。")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, ConfigurationUI.sheetPanelPadding)
            .padding(.top, 2)
    }
}
#endif
