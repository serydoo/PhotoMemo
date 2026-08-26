#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@MainActor
@Suite("Output language isolation")
struct OutputLanguageIsolationTests {

    @Test("resolves Japanese and Korean system languages")
    func resolvesJapaneseAndKoreanSystemLanguages() {
        #expect(
            MemoMarkLanguage.resolved(
                from: Locale(identifier: "ja-JP")
            ) == .japanese
        )
        #expect(
            MemoMarkLanguage.resolved(
                from: Locale(identifier: "ko-KR")
            ) == .korean
        )
        #expect(
            MemoMarkLanguage.resolved(
                from: Locale(identifier: "xx-XX")
            ) == .english
        )
        #expect(
            MemoMarkLanguagePreference.japanese.resolvedLanguage
                == .japanese
        )
        #expect(
            MemoMarkLanguagePreference.korean.resolvedLanguage
                == .korean
        )
        #expect(
            MemoMarkInterfaceLanguagePreference.japanese
                .resolvedLanguage == .japanese
        )
        #expect(
            MemoMarkInterfaceLanguagePreference.korean
                .resolvedLanguage == .korean
        )
    }

    @Test("editing session reads and writes the selected Preset output language")
    func sessionOwnsSelectedPresetOutputLanguage() {
        var state = ConfigurationCenterState.mock
        state.memoryPresets[0].language = .japanese
        state.memoryPresets[1].language = .korean

        let session = ConfigurationSession(state: state)

        #expect(session.presetOutputLanguage == .japanese)
        session.selectMemoryPreset(state.memoryPresets[1])
        #expect(session.presetOutputLanguage == .korean)

        session.presetOutputLanguage = .english
        #expect(session.state.selectedMemoryPreset?.language == .english)
        #expect(
            session.defaultOutputLanguage
            == MemoMarkLanguage.defaultOutputLanguage
        )
    }

    @Test("changing interface language does not rewrite Preset output language")
    func interfaceLanguageChangeDoesNotRewritePresetOutputLanguage() {
        let defaults = MemoMarkSharedContainer.sharedUserDefaults
        let key = MemoMarkLanguage.interfacePreferenceStorageKey
        let previousValue = defaults.object(forKey: key)
        defer {
            if let previousValue {
                defaults.set(previousValue, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }

        var state = ConfigurationCenterState.mock
        state.memoryPresets[0].language = .japanese
        let session = ConfigurationSession(state: state)

        MemoMarkLanguage.persistInterfacePreference(.simplifiedChinese)
        #expect(session.presetOutputLanguage == .japanese)

        MemoMarkLanguage.persistInterfacePreference(.english)
        #expect(session.presetOutputLanguage == .japanese)
    }

    @Test("saving a Preset preserves its output language")
    func persistencePreservesPresetOutputLanguage() {
        var state = ConfigurationCenterState.mock
        state.memoryPresets[0].language = .japanese

        let editingState = ConfigurationEditingState(state: state)
        let reconciler = ConfigurationPersistenceReconciler()
        let saved = reconciler.configurationSnapshot(
            in: state.memoryPresets[0],
            editingState: editingState,
            savedAt: Date(timeIntervalSince1970: 1),
            logoMode: nil,
            outputConfiguration: nil
        )

        #expect(saved.language == .japanese)
    }

    @Test("configuration snapshots freeze the selected Preset output language")
    func configurationSnapshotFreezesPresetOutputLanguage() throws {
        var state = ConfigurationCenterState.mock
        state.memoryPresets[0].language = .korean

        let session = ConfigurationSession(state: state)
        let snapshot = try #require(
            ConfigurationSnapshotBuilder.build(from: session)
        )

        #expect(snapshot.language == .korean)
    }

    @Test("Configuration Center preview uses Preset output language")
    func configurationCenterPreviewUsesPresetOutputLanguage() throws {
        let defaults = MemoMarkSharedContainer.sharedUserDefaults
        let key = MemoMarkLanguage.interfacePreferenceStorageKey
        let previousValue = defaults.object(forKey: key)
        defer {
            if let previousValue {
                defaults.set(previousValue, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }

        var state = ConfigurationCenterState.mock
        state.memoryPresets[0].language = .japanese
        let session = ConfigurationSession(state: state)

        MemoMarkLanguage.persistInterfacePreference(.simplifiedChinese)

        let previewText = try #require(
            session.generatedMemoryModule?.renderedText
        )

        #expect(previewText.contains("歳") || previewText.contains("か月"))
        #expect(!previewText.contains("岁"))
        #expect(session.presetOutputLanguage == .japanese)
    }
}
#endif
