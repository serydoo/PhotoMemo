#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 iOS subject overview presenter")
struct V1IOSSubjectOverviewPresenterTests {

    @Test("presentation reflects selected anchor and subject facts")
    func presentationReflectsSelectedAnchorAndSubjectFacts() {
        let subject =
            MemorySubject(
                identity: .init(
                    displayName: "小宝成长记录",
                    shortName: "小宝"
                ),
                relationship: .init(
                    role: "family",
                    label: "成长记录"
                ),
                definition: "围绕成长阶段持续记录。",
                referenceDate: Date(
                    timeIntervalSince1970: 0
                ),
                timeAnchors: [
                    .init(
                        title: "生日",
                        date: Date(
                            timeIntervalSince1970: 0
                        ),
                        note: "小宝出生日期"
                    ),
                    .init(
                        title: "入园",
                        date: Date(
                            timeIntervalSince1970: 86_400
                        ),
                        note: "第一次去幼儿园"
                    )
                ],
                behavior: .init(
                    primaryAnchor: "生日",
                    iconStrategy: .autoMatch,
                    badgeStrategy: .fixed,
                    memoryExpression: .init(
                        title: "默认表达",
                        blocks: []
                    )
                ),
                decorations: []
            )

        let presentation =
            V1IOSSubjectOverviewPresenter
            .presentation(
                subject: subject,
                currentTimeAnchorTitle: "生日",
                currentTimeAnchorDescription: "小宝出生日期"
            )
        let expectedAnchorDateLabel =
            Date(timeIntervalSince1970: 0)
            .formatted(
                .dateTime
                    .year()
                    .month()
                    .day()
                    .locale(Locale(identifier: "zh_CN"))
            )

        #expect(presentation.title == "小宝")
        #expect(presentation.subtitle == "成长记录")
        #expect(presentation.expressionSubjectTitle == "显示名称")
        #expect(presentation.expressionSubjectValue == "小宝成长记录")
        #expect(presentation.anchorTitle == "生日")
        #expect(
            presentation.anchorDateLabel
            == expectedAnchorDateLabel
        )
        #expect(presentation.anchorDescription == "小宝出生日期")
    }

    @Test("presentation falls back when subject is unavailable")
    func presentationFallsBackWhenSubjectIsUnavailable() {
        let presentation =
            V1IOSSubjectOverviewPresenter
            .presentation(
                subject: nil,
                currentTimeAnchorTitle: "",
                currentTimeAnchorDescription: ""
            )

        #expect(presentation.title == "记忆对象")
        #expect(presentation.subtitle == "补充主角信息")
        #expect(presentation.expressionSubjectTitle == "显示名称")
        #expect(presentation.expressionSubjectValue == "记忆对象")
        #expect(presentation.anchorTitle == "未设置")
        #expect(presentation.anchorDateLabel == "未设置")
    }

    @Test("configuration flow keeps a draft copy until save")
    func configurationFlowKeepsDraftCopyUntilSave() throws {
        let originalAnchor =
            MemorySubject.TimeAnchor(
                title: "生日",
                date: Date(timeIntervalSince1970: 0),
                note: "原始说明"
            )
        let originalSubject =
            MemorySubject(
                identity: .init(
                    displayName: "小宝成长记录",
                    shortName: "小宝"
                ),
                relationship: .init(
                    role: "family",
                    label: "成长记录"
                ),
                definition: "围绕成长阶段持续记录。",
                referenceDate: originalAnchor.date,
                timeAnchors: [originalAnchor],
                behavior: .init(
                    primaryAnchor: "生日",
                    iconStrategy: .autoMatch,
                    badgeStrategy: .fixed,
                    memoryExpression: .init(
                        title: "默认表达",
                        blocks: []
                    )
                ),
                decorations: []
            )
        let liveSession =
            ConfigurationSession(
                state: ConfigurationCenterState(
                    subjects: [originalSubject],
                    selectedSubjectID: originalSubject.id,
                    memoryPresets: [],
                    selectedMemoryPresetID: nil,
                    cardSelection: .init(selectedRegion: .subject),
                    selectedBlockID: nil,
                    tokenLibrary: .init(),
                    availableDecorations: [],
                    regionPreviewTexts: [:]
                )
            )

        let flow =
            V1IOSSubjectConfigurationFlowPresenter
            .makeFlowState(from: liveSession)

        #expect(flow?.sourceSubjectID == originalSubject.id)
        #expect(
            flow?.draftSession.state.selectedSubject?.identity.displayName
            == "小宝成长记录"
        )

        var updatedDraft =
            try #require(
                flow?.draftSession.state.selectedSubject
            )
        updatedDraft.identity.displayName = "新的名字"
        flow?.draftSession.updateSelectedSubject(updatedDraft)

        #expect(
            liveSession.state.selectedSubject?.identity.displayName
            == "小宝成长记录"
        )

        flow?.saveChanges()

        #expect(
            liveSession.state.selectedSubject?.identity.displayName
            == "新的名字"
        )
    }

    @Test("configuration flow save can persist updated subject through an external save hook")
    func configurationFlowSaveCanPersistUpdatedSubjectThroughExternalSaveHook() throws {
        let originalSubject =
            MemorySubject(
                identity: .init(
                    displayName: "小宝成长记录",
                    shortName: "小宝"
                ),
                relationship: .init(
                    role: "family",
                    label: "成长记录"
                ),
                definition: "围绕成长阶段持续记录。",
                referenceDate: Date(timeIntervalSince1970: 0),
                timeAnchors: [
                    .init(
                        title: "生日",
                        date: Date(timeIntervalSince1970: 0),
                        note: "原始说明",
                        anchorType: .birthday
                    )
                ],
                expressionSubjectSource: .displayName,
                behavior: .init(
                    primaryAnchor: "生日",
                    iconStrategy: .autoMatch,
                    badgeStrategy: .fixed,
                    memoryExpression: .init(
                        title: "默认表达",
                        blocks: []
                    )
                ),
                decorations: []
            )
        let liveSession =
            ConfigurationSession(
                state: ConfigurationCenterState(
                    subjects: [originalSubject],
                    selectedSubjectID: originalSubject.id,
                    memoryPresets: [],
                    selectedMemoryPresetID: nil,
                    cardSelection: .init(selectedRegion: .subject),
                    selectedBlockID: nil,
                    tokenLibrary: .init(),
                    availableDecorations: [],
                    regionPreviewTexts: [:]
                )
            )

        var persistedSubject: MemorySubject?
        let flow =
            V1IOSSubjectConfigurationFlowState(
                liveSession: liveSession,
                persistSubject: { subject in
                    persistedSubject = subject
                }
            )

        var updatedDraft =
            try #require(
                flow?.draftSession.state.selectedSubject
            )
        updatedDraft.expressionSubjectSource = .shortName
        flow?.draftSession.updateSelectedSubject(updatedDraft)

        flow?.saveChanges()

        #expect(
            persistedSubject?.expressionSubjectSource
            == .shortName
        )
        #expect(
            liveSession.state.selectedSubject?.expressionSubjectSource
            == .shortName
        )
    }

    @Test("subject overview save writes the latest subject to the durable aggregate")
    func subjectOverviewSaveWritesLatestSubjectToDurableAggregate() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )

        #expect(source.contains("persistCurrentSubjectChanges"))
        #expect(source.contains("V1LocalConfigurationLibraryPresenter"))
        #expect(source.contains(".updatingSubject("))
        #expect(source.contains(".saveConfigurationLibrary(candidate)"))
        #expect(source.contains(".updateConfigurationLibraryReference("))
        #expect(
            source.contains(
                "onPersistSubjectChanges: persistCurrentSubjectChanges"
            )
        )
    }

    @Test("subject overview keeps compact current identity actions and uses the object display name")
    func subjectOverviewKeepsCompactCurrentIdentityActionsAndUsesDisplayName() throws {
        let railSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewRailSurface.swift"
        )
        let normalizedRail = railSource.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )

        let summaryStart = try #require(
            railSource.range(of: "private var currentSubjectSummary")
        )
        let summaryEnd = try #require(
            railSource.range(
                of: "private var switchingLayout",
                range: summaryStart.upperBound..<railSource.endIndex
            )
        )
        let summarySource = String(
            railSource[summaryStart.lowerBound..<summaryEnd.lowerBound]
        )

        #expect(!summarySource.contains("V1SubjectAvatarView"))
        #expect(!summarySource.contains("subjectRelationship(subject)"))
        #expect(railSource.contains("ViewThatFits(in: .horizontal)"))
        #expect(
            normalizedRail.contains(
                "Image(systemName: \"checkmark\")"
            )
        )
        #expect(!normalizedRail.contains("Label(\"保存\", systemImage: \"checkmark\")"))
        #expect(
            normalizedRail.contains(
                "Label( \"切换对象\", systemImage: \"arrow.left.arrow.right\" )"
            )
        )

        let badgeIndex = try #require(
            summarySource.range(of: "V1IOSHomeStatusBadge")?.lowerBound
        )
        let nameIndex = try #require(
            summarySource.range(of: "Text(stableSubjectDisplayName(subject))")?.lowerBound
        )
        #expect(badgeIndex < nameIndex)
        #expect(!summarySource.contains("subjectDisplayName(subject)"))
        #expect(railSource.contains("subject.identity.displayName"))
    }

    @Test("expression subject is one selectable row that explains source and output")
    func expressionSubjectIsOneSelectableRowThatExplainsSourceAndOutput() throws {
        let editorSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let expressionSource = try sourceSection(
            in: editorSource,
            from: "private var expressionSubjectMenuRow",
            to: "private var compactIdentityFieldsPanel"
        )
        #expect(expressionSource.contains("Menu {"))
        #expect(expressionSource.contains("Text(\"表达称呼\")"))
        #expect(expressionSource.contains("Text(expressionSubjectDisplayValue)"))
        #expect(
            expressionSource.contains(
                "Text(\"· 来自“\\(expressionSubjectDisplaySourceTitle)”\")"
            )
        )
        #expect(
            expressionSource.contains(
                "expressionSubjectMenuOptionTitle(for: source)"
            )
        )
        #expect(
            expressionSource.contains(
                ".disabled(expressionSubjectSourceValue(for: source) == nil)"
            )
        )
        #expect(
            expressionSource.contains(
                "ConfigurationUI.selectedBackground"
            )
        )
        #expect(
            !expressionSource.contains(
                ".stroke(Color.accentColor.opacity(0.22))"
            )
        )
        #expect(!expressionSource.contains("expressionSubjectResult"))
        #expect(!expressionSource.contains("Text(\"主体名称\")"))
        #expect(!expressionSource.contains("Text(\"当前展示\")"))
        #expect(
            editorSource.contains(
                "MemorySubject.resolveExpressionSubject("
            )
        )
    }

    @Test("compact basic information uses native rows without per-field rounded boxes")
    func compactBasicInformationUsesNativeRowsWithoutPerFieldRoundedBoxes() throws {
        let editorSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let panelSource = try sourceSection(
            in: editorSource,
            from: "private var compactIdentityFieldsPanel",
            to: "private func compactLabeledTextField"
        )
        let fieldSource = try sourceSection(
            in: editorSource,
            from: "private func compactLabeledTextField",
            to: "private var expressionSubjectDisplayValue"
        )
        let normalizedPanel = panelSource.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )

        #expect(normalizedPanel.contains("compactLabeledTextField( \"对象名称\""))
        #expect(normalizedPanel.contains("compactLabeledTextField( \"昵称\""))
        #expect(normalizedPanel.contains("compactLabeledTextField( \"与我的关系\""))
        #expect(normalizedPanel.contains("compactLabeledTextField( \"专属称呼\""))
        #expect(!normalizedPanel.contains("compactLabeledTextField( \"显示名称\""))
        #expect(!normalizedPanel.contains("compactLabeledTextField( \"关系\""))
        #expect(!normalizedPanel.contains("compactLabeledTextField( \"关系备注\""))

        #expect(fieldSource.contains(".textFieldStyle(.plain)"))
        #expect(!fieldSource.contains("RoundedRectangle("))
        #expect(!panelSource.contains("RoundedRectangle("))
    }
}

private extension V1IOSSubjectOverviewPresenterTests {

    func sourceText(_ relativePath: String) throws -> String {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }

    func sourceSection(
        in source: String,
        from startMarker: String,
        to endMarker: String
    ) throws -> String {
        let start = try #require(source.range(of: startMarker))
        let end = try #require(
            source.range(
                of: endMarker,
                range: start.upperBound..<source.endIndex
            )
        )
        return String(source[start.lowerBound..<end.lowerBound])
    }
}
#endif
