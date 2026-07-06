#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 configuration status")
struct V1ConfigurationStatusTests {

    @Test("context-specific messages come from status instead of driving it")
    func contextSpecificMessagesComeFromStatusInsteadOfDrivingIt() {
        #expect(
            V1ConfigurationStatus.idle.message(for: .defaultConfiguration)
            == "尚未保存为当前配置"
        )
        #expect(
            V1ConfigurationStatus.idle.message(for: .shareConfiguration)
            == "尚未保存为分享配置"
        )
        #expect(
            V1ConfigurationStatus.saved.message(for: .preset)
            == "当前生效"
        )
        #expect(
            V1ConfigurationStatus.saved.message(for: .defaultConfiguration)
            == "已保存为当前配置"
        )
        #expect(
            V1ConfigurationStatus.subjectSynced.message(for: .shareConfiguration)
            == "记忆对象已同步"
        )
    }

    @Test("status tone follows semantic state instead of localized copy")
    func statusToneFollowsSemanticStateInsteadOfLocalizedCopy() {
        #expect(V1ConfigurationStatus.saved.tone == .accent)
        #expect(V1ConfigurationStatus.subjectSynced.tone == .accent)
        #expect(V1ConfigurationStatus.dirty.tone == .warning)
        #expect(V1ConfigurationStatus.failure(message: "保存失败").tone == .warning)
        #expect(V1ConfigurationStatus.saving.tone == .neutral)
    }
}
#endif
