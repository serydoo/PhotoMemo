#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("V1 draft bridge")
struct V1DraftBridgeTests {

    @Test("preview and mutation projections preserve item metadata")
    func previewAndMutationProjectionsPreserveItemMetadata() {
        let tokenID = UUID()
        let draft =
            V1EditorDraft(
                items: [
                    .text("记录"),
                    V1ContentItem(
                        id: tokenID,
                        kind: .token,
                        title: "设备",
                        value: "iPhone 17 Pro Max",
                        savedValue: "{{camera_model}}",
                        systemImage: "camera"
                    ),
                    .separator("·")
                ]
            )

        let previewDraft =
            V1DraftBridge.previewDraft(
                from: draft
            )
        let mutationDraft =
            V1DraftBridge.mutationDraft(
                from: draft
            )

        #expect(
            previewDraft.items[1].id == tokenID
        )
        #expect(
            previewDraft.items[1].title == "设备"
        )
        #expect(
            previewDraft.items[1].savedValue
            == "{{camera_model}}"
        )
        #expect(
            previewDraft.items[1].systemImage
            == "camera"
        )
        #expect(
            mutationDraft.items[1].id == tokenID
        )
        #expect(
            mutationDraft.items[1].title == "设备"
        )
        #expect(
            mutationDraft.items[1].savedValue
            == "{{camera_model}}"
        )
        #expect(
            mutationDraft.items[1].systemImage
            == "camera"
        )
    }

    @Test("editor draft round trips through preview and mutation bridges")
    func editorDraftRoundTripsThroughPreviewAndMutationBridges() {
        let draft =
            V1EditorDraft(
                items: [
                    .text("记录"),
                    .separator("·"),
                    V1ContentItem(
                        id: UUID(),
                        kind: .lineBreak,
                        title: "换行",
                        value: "",
                        savedValue: "",
                        systemImage: "return"
                    )
                ]
            )

        let fromPreview =
            V1DraftBridge.editorDraft(
                from:
                    V1DraftBridge
                    .previewDraft(from: draft)
            )
        let fromMutation =
            V1DraftBridge.editorDraft(
                from:
                    V1DraftBridge
                    .mutationDraft(from: draft)
            )

        #expect(fromPreview == draft)
        #expect(fromMutation == draft)
    }

    @Test("view state projection preserves active ids and typed status")
    func viewStateProjectionPreservesActiveIDsAndTypedStatus() {
        let textID = UUID()
        let state =
            V1DraftBridge.mutationState(
                regionDrafts: [
                    .slotA: .init(
                        items: [
                            V1ContentItem(
                                id: textID,
                                kind: .text,
                                title: "文字",
                                value: "记录",
                                savedValue: "记录",
                                systemImage: "textformat"
                            )
                        ]
                    )
                ],
                activeTextItemIDs: [.slotA: textID],
                activeConfigurationStatus: .dirty
            )

        let viewState =
            V1DraftBridge.viewState(
                from: state
            )

        #expect(
            viewState.regionDrafts[.slotA]?.items.first?.id
            == textID
        )
        #expect(
            viewState.activeTextItemIDs[.slotA]
            == textID
        )
        #expect(
            viewState.activeConfigurationStatus
            == .dirty
        )
    }

    @Test("structured editor clipboard preserves literal and module order")
    func structuredEditorClipboardPreservesLiteralAndModuleOrder() throws {
        let draft = V1EditorDraft(
            items: [
                .text("他爸"),
                .token(
                    "设备型号",
                    value: "iPhone 17 Pro Max",
                    templateValue: "{{model}}",
                    systemImage: "camera.fill"
                ),
                .text("，在"),
                .token(
                    "位置",
                    value: "示例市",
                    templateValue: "{{location_display}}",
                    systemImage: "location.fill"
                )
            ]
        )

        let payload = V1EditorClipboardPayload(items: draft.items)
        let encoded = try #require(V1EditorClipboardCodec.encode(payload))
        let decoded = try #require(
            V1EditorClipboardCodec.decode(encoded)
        )

        #expect(decoded.items == draft.items)
        #expect(decoded.items[1].savedValue == "{{model}}")
        #expect(decoded.items[3].savedValue == "{{location_display}}")
        #expect(decoded.displayText == "他爸iPhone 17 Pro Max，在示例市")

        let pastedItems = decoded.items.map(\.copyingForInsertion)
        #expect(pastedItems.map(\.kind) == decoded.items.map(\.kind))
        #expect(pastedItems.map(\.savedValue) == decoded.items.map(\.savedValue))
        #expect(pastedItems.map(\.id).allSatisfy { id in
            !decoded.items.map(\.id).contains(id)
        })

        let incompatible = V1EditorClipboardPayload(
            items: draft.items,
            schema: V1EditorClipboardPayload.schemaVersion + 1
        )
        let incompatibleData = try #require(
            V1EditorClipboardCodec.encode(incompatible)
        )
        #expect(V1EditorClipboardCodec.decode(incompatibleData) == nil)
    }

    @Test("unresolved module keeps its canonical expression and gets a visible fallback")
    func unresolvedModuleKeepsCanonicalExpressionAndGetsFallback() {
        let item = V1ContentItem.token(
            "无法识别的内容",
            value: "原始模块",
            templateValue: "{{future_module}}",
            systemImage: "curlybraces"
        )

        #expect(item.isUnresolvedModule)
        #expect(item.canonicalModuleExpression == "{{future_module}}")
        #expect(item.editorModuleTitle == "无法识别的内容")
        #expect(item.editorModuleSystemImage == "exclamationmark.triangle")
        #expect(!item.editorModuleAccessibilityLabel.isEmpty)
    }
}
#endif
