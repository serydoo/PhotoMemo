#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1RegionEditorCluster: View {

    let expansionBinding: (CardRegion) -> Binding<Bool>
    let draft: (CardRegion) -> V1EditorDraft
    let resolvedText: (V1EditorDraft) -> String
    let onFocus: () -> Void
    let onFocusTextItem: (CardRegion, V1ContentItem) -> Void
    let onUpdateTextItem: (CardRegion, V1ContentItem, String) -> Void
    let onPrependText: (CardRegion, String) -> Void
    let onAppendText: (CardRegion, String) -> Void
    let onRemoveItem: (CardRegion, V1ContentItem) -> Void
    let onShowModules: (CardRegion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            IOSCompactEntryListGroup {
                ForEach(CardRegion.memoryCardRegions, id: \.self) { region in
                    let regionDraft = draft(region)

                    V1RegionEditorCard(
                        region: region,
                        isExpanded: expansionBinding(region),
                        showsDivider:
                            region != CardRegion.memoryCardRegions.last,
                        draft: regionDraft,
                        resolvedText: resolvedText(regionDraft),
                        onFocus: onFocus,
                        onFocusTextItem: { item in
                            onFocusTextItem(region, item)
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
                        onShowModules: {
                            onShowModules(region)
                        }
                    )
                }
            }

            configurationGuide
                .padding(.horizontal, 4)
        }
    }

    private var configurationGuide: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("写进卡片的内容")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("卡片上的四个位置，都能写下你的话，也能放入照片里的时间、地点和拍摄信息。需要时，这段回忆也可以写进新照片的说明里。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
#endif
