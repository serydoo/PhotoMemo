#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("V1 configuration status")
struct ConfigurationPersistenceStatusTests {

    @Test("context-specific messages come from status instead of driving it")
    func contextSpecificMessagesComeFromStatusInsteadOfDrivingIt() {
        #expect(
            ConfigurationPersistenceStatus.idle.message(for: .defaultConfiguration)
            == "尚未保存为当前配置"
        )
        #expect(
            ConfigurationPersistenceStatus.idle.message(for: .shareConfiguration)
            == "尚未保存为分享配置"
        )
        #expect(
            ConfigurationPersistenceStatus.saved.message(for: .preset)
            == "当前生效"
        )
        #expect(
            ConfigurationPersistenceStatus.saved.message(for: .defaultConfiguration)
            == "已保存为当前配置"
        )
        #expect(
            ConfigurationPersistenceStatus.subjectSynced.message(for: .shareConfiguration)
            == "记忆对象已同步"
        )
    }

    @Test("status tone follows semantic state instead of localized copy")
    func statusToneFollowsSemanticStateInsteadOfLocalizedCopy() {
        #expect(ConfigurationPersistenceStatus.saved.tone == .accent)
        #expect(ConfigurationPersistenceStatus.subjectSynced.tone == .accent)
        #expect(ConfigurationPersistenceStatus.dirty.tone == .warning)
        #expect(
            ConfigurationPersistenceStatus
                .savedWithWarning(message: "同步失败")
                .tone == .warning
        )
        #expect(ConfigurationPersistenceStatus.failure(message: "保存失败").tone == .warning)
        #expect(ConfigurationPersistenceStatus.saving.tone == .neutral)
    }

    @Test("switch protection includes dirty and failed saves but not synchronized subjects")
    func switchProtectionTracksEveryUncommittedState() {
        #expect(ConfigurationPersistenceStatus.dirty.hasUncommittedChanges)
        #expect(!ConfigurationPersistenceStatus.subjectSynced.hasUncommittedChanges)
        #expect(
            ConfigurationPersistenceStatus.failure(message: "保存失败")
                .hasUncommittedChanges
        )
        #expect(!ConfigurationPersistenceStatus.idle.hasUncommittedChanges)
        #expect(!ConfigurationPersistenceStatus.saving.hasUncommittedChanges)
        #expect(!ConfigurationPersistenceStatus.saved.hasUncommittedChanges)
        #expect(
            !ConfigurationPersistenceStatus
                .savedWithWarning(message: "同步失败")
                .hasUncommittedChanges
        )
    }
}
#endif
