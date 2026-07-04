#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 configuration apply reconciliation")
struct V1ConfigurationApplyReconciliationTests {

    @Test("project success patch for new album with picker selection reloads albums restores subject and marks preset applied")
    func projectSuccessPatchForNewAlbumWithPickerSelectionReloadsAlbumsRestoresSubjectAndMarksPresetApplied() {
        let subject = ConfigurationCenterState.mock.selectedSubject
        let receipt = V1ConfigurationApplyReceipt(
            saveReceipt: V1ConfigurationSaveReceipt(
                anchor: Anchor(
                    type: .birthday,
                    title: "生日",
                    date: Date(timeIntervalSince1970: 1_725_206_400)
                )
            ),
            albumSelection: V1ResolvedAlbumSelection(
                identifier: "album-1",
                title: "成长记录",
                pickerSelectionIdentifier: "picker-album-1"
            )
        )

        let patch = V1ConfigurationApplyResultPresenter.successPatch(
            receipt: receipt,
            outputTarget: .newAlbum,
            subjectForSaving: subject
        )

        #expect(patch.shouldReloadAlbums == true)
        #expect(patch.selectedExistingAlbumIdentifier == "picker-album-1")
        #expect(patch.subjectToRestore == subject)
        #expect(patch.shouldApplySelectedMemoryPreset == true)
        #expect(patch.activeConfigurationMessage == "已保存为分享配置")
        #expect(patch.isSavingConfiguration == false)
    }

    @Test("project failure patch surfaces error and skips success state")
    func projectFailurePatchSurfacesErrorAndSkipsSuccessState() {
        let patch = V1ConfigurationApplyResultPresenter.failurePatch(
            error: PhotoMemoError(
                code: .invalidInput,
                message: "保存失败"
            )
        )

        #expect(patch.shouldReloadAlbums == false)
        #expect(patch.selectedExistingAlbumIdentifier == nil)
        #expect(patch.subjectToRestore == nil)
        #expect(patch.shouldApplySelectedMemoryPreset == false)
        #expect(patch.activeConfigurationMessage == "保存失败")
        #expect(patch.isSavingConfiguration == false)
    }
}
#endif
