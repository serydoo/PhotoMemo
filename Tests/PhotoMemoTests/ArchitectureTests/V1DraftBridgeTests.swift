#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

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

    @Test("view state projection preserves active ids and dirty message")
    func viewStateProjectionPreservesActiveIDsAndDirtyMessage() {
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
                activeConfigurationMessage: "有未保存修改"
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
            viewState.activeConfigurationMessage
            == "有未保存修改"
        )
    }
}
#endif
