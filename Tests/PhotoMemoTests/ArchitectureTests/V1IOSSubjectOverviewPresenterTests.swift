#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 iOS subject overview presenter")
struct V1IOSSubjectOverviewPresenterTests {

    @Test("presentation uses the edited object name instead of a stale nickname")
    func presentationUsesEditedObjectNameInsteadOfStaleNickname() {
        let subject =
            MemorySubject(
                identity: .init(
                    displayName: "小宝",
                    shortName: "儿子啊"
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
        #expect(presentation.expressionSubjectTitle == "对象名称")
        #expect(presentation.expressionSubjectValue == "小宝")
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
        #expect(presentation.expressionSubjectTitle == "对象名称")
        #expect(presentation.expressionSubjectValue == "记忆对象")
        #expect(presentation.anchorTitle == "未设置")
        #expect(presentation.anchorDateLabel == "未设置")
    }

    @Test("an unavailable optional expression subject always falls back to object name")
    func unavailableOptionalExpressionSubjectFallsBackToObjectName() {
        let subject =
            MemorySubject(
                identity: .init(
                    displayName: "小宝",
                    shortName: ""
                ),
                relationship: .init(
                    role: "家人",
                    label: "宝贝"
                ),
                referenceDate: Date(timeIntervalSince1970: 0),
                expressionSubjectSource: .shortName,
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
                currentTimeAnchorDescription: ""
            )

        #expect(presentation.expressionSubjectTitle == "对象名称")
        #expect(presentation.expressionSubjectValue == "小宝")
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

    @Test("configuration flow commits a fallback anchor after deleting its current anchor")
    func configurationFlowCommitsFallbackAnchorAfterDeletingCurrentAnchor() throws {
        let birthday = MemorySubject.TimeAnchor(
            title: "生日",
            date: Date(timeIntervalSince1970: 0),
            note: "出生日期",
            anchorType: .birthday
        )
        let school = MemorySubject.TimeAnchor(
            title: "入园",
            date: Date(timeIntervalSince1970: 86_400),
            note: "第一次去幼儿园",
            anchorType: .custom
        )
        let subject = MemorySubject(
            identity: .init(displayName: "小宝", shortName: "宝宝"),
            relationship: .init(role: "家人", label: "成长记录"),
            definition: "围绕成长阶段持续记录。",
            referenceDate: birthday.date,
            timeAnchors: [birthday, school],
            activeTimeAnchorID: birthday.id,
            behavior: .init(
                primaryAnchor: birthday.title,
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(title: "默认表达", blocks: [])
            ),
            decorations: []
        )
        let liveSession = ConfigurationSession(
            state: ConfigurationCenterState(
                subjects: [subject],
                selectedSubjectID: subject.id,
                memoryPresets: [],
                selectedMemoryPresetID: nil,
                cardSelection: .init(selectedRegion: .subject),
                selectedBlockID: nil,
                tokenLibrary: .init(),
                availableDecorations: [],
                regionPreviewTexts: [:]
            )
        )
        let flow = try #require(
            V1IOSSubjectConfigurationFlowState(liveSession: liveSession)
        )
        let draft = try #require(flow.draftSession.state.selectedSubject)
        let updatedDraft = try #require(
            draft.removingTimeAnchor(id: birthday.id)
        )

        flow.draftSession.updateSelectedSubject(updatedDraft)

        #expect(flow.saveChanges() == true)
        #expect(
            liveSession.state.selectedSubject?.timeAnchors
            == [school]
        )
        #expect(
            liveSession.state.selectedSubject?.activeTimeAnchorID
            == school.id
        )
        #expect(
            liveSession.state.selectedSubject?.behavior.primaryAnchor
            == school.title
        )
        #expect(
            liveSession.state.selectedSubject?.referenceDate
            == school.date
        )
    }

    @Test("removing a noncurrent anchor preserves the current anchor projection")
    func removingNoncurrentAnchorPreservesCurrentAnchorProjection() throws {
        let birthday = MemorySubject.TimeAnchor(
            title: "生日",
            date: Date(timeIntervalSince1970: 0),
            note: "出生日期",
            anchorType: .birthday
        )
        let school = MemorySubject.TimeAnchor(
            title: "入园",
            date: Date(timeIntervalSince1970: 86_400),
            note: "第一次去幼儿园",
            anchorType: .custom
        )
        let subject = MemorySubject(
            identity: .init(displayName: "小宝", shortName: "宝宝"),
            relationship: .init(role: "家人", label: "成长记录"),
            referenceDate: school.date,
            timeAnchors: [birthday, school],
            activeTimeAnchorID: school.id,
            behavior: .init(
                primaryAnchor: school.title,
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(title: "默认表达", blocks: [])
            ),
            decorations: []
        )

        let updated = try #require(
            subject.removingTimeAnchor(id: birthday.id)
        )

        #expect(updated.timeAnchors == [school])
        #expect(updated.activeTimeAnchorID == school.id)
        #expect(updated.behavior.primaryAnchor == school.title)
        #expect(updated.referenceDate == school.date)
    }

    @Test("configuration flow rejects an empty object name")
    func configurationFlowRejectsEmptyObjectName() throws {
        let anchor = MemorySubject.TimeAnchor(
            title: "生日",
            date: Date(timeIntervalSince1970: 0),
            note: "原始说明",
            anchorType: .birthday
        )
        let subject = MemorySubject(
            identity: .init(displayName: "原名称", shortName: "小宝"),
            relationship: .init(role: "family", label: "成长记录"),
            definition: "围绕成长阶段持续记录。",
            referenceDate: anchor.date,
            timeAnchors: [anchor],
            behavior: .init(
                primaryAnchor: anchor.title,
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(title: "默认表达", blocks: [])
            ),
            decorations: []
        )
        let liveSession = ConfigurationSession(
            state: ConfigurationCenterState(
                subjects: [subject],
                selectedSubjectID: subject.id,
                memoryPresets: [],
                selectedMemoryPresetID: nil,
                cardSelection: .init(selectedRegion: .subject),
                selectedBlockID: nil,
                tokenLibrary: .init(),
                availableDecorations: [],
                regionPreviewTexts: [:]
            )
        )
        let flow = try #require(
            V1IOSSubjectConfigurationFlowState(liveSession: liveSession)
        )
        var draft = try #require(flow.draftSession.state.selectedSubject)
        draft.identity.displayName = " \n\t"
        flow.draftSession.updateSelectedSubject(draft)

        #expect(flow.canSaveChanges == false)
        #expect(flow.saveChanges() == false)
        #expect(
            liveSession.state.selectedSubject?.identity.displayName == "原名称"
        )
    }

    @Test("removing an avatar clears every derived identity reference together")
    func removingAvatarClearsEveryDerivedIdentityReference() {
        var identity = MemorySubject.Identity(
            displayName: "小宝",
            shortName: "宝宝",
            avatarImagePath: "/tmp/display.png",
            avatarBadgeImagePath: "/tmp/badge.png",
            avatarPreviewImagePath: "/tmp/preview.png"
        )

        identity.removeAvatarAssets()

        #expect(identity.avatarImagePath == nil)
        #expect(identity.avatarBadgeImagePath == nil)
        #expect(identity.avatarPreviewImagePath == nil)
    }

    @Test("configuration flow commits identity and time anchor edits together")
    func configurationFlowCommitsIdentityAndTimeAnchorEdits() throws {
        let anchor = MemorySubject.TimeAnchor(
            title: "生日",
            date: Date(timeIntervalSince1970: 0),
            note: "原始说明",
            anchorType: .birthday
        )
        let subject = MemorySubject(
            identity: .init(displayName: "原名称", shortName: "小宝"),
            relationship: .init(role: "family", label: "成长记录"),
            definition: "围绕成长阶段持续记录。",
            referenceDate: anchor.date,
            timeAnchors: [anchor],
            behavior: .init(
                primaryAnchor: anchor.title,
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(title: "默认表达", blocks: [])
            ),
            decorations: []
        )
        let liveSession = ConfigurationSession(
            state: ConfigurationCenterState(
                subjects: [subject],
                selectedSubjectID: subject.id,
                memoryPresets: [],
                selectedMemoryPresetID: nil,
                cardSelection: .init(selectedRegion: .subject),
                selectedBlockID: nil,
                tokenLibrary: .init(),
                availableDecorations: [],
                regionPreviewTexts: [:]
            )
        )
        let flow = try #require(
            V1IOSSubjectConfigurationFlowState(liveSession: liveSession)
        )
        var draft = try #require(flow.draftSession.state.selectedSubject)
        draft.identity.displayName = "新名称"
        var updatedAnchor = anchor
        updatedAnchor.title = "被误改的锚点"
        updatedAnchor.date = Date(timeIntervalSince1970: 86_400)
        draft = try #require(
            draft.replacingTimeAnchor(updatedAnchor)
        )
        flow.draftSession.updateSelectedSubject(draft)

        #expect(flow.saveChanges() == true)
        let saved = try #require(liveSession.state.selectedSubject)
        #expect(saved.identity.displayName == "新名称")
        #expect(saved.timeAnchors[0].title == "被误改的锚点")
        #expect(saved.activeTimeAnchorID == anchor.id)
        #expect(saved.behavior.primaryAnchor == "被误改的锚点")
        #expect(
            saved.referenceDate
            == Date(timeIntervalSince1970: 86_400)
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
        #expect(railSource.contains("V1IOSSubjectOverviewSubjectRail"))
        #expect(railSource.contains("accessibilityLabel(\"切换到"))
        #expect(!normalizedRail.contains("保存"))
        #expect(!normalizedRail.contains("当前使用"))
    }

    @Test("expression subject is a standalone Contacts-style source card")
    func expressionSubjectIsStandaloneSourceCard() throws {
        let editorSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let expressionSource = try sourceSection(
            in: editorSource,
            from: "private var expressionSubjectCard",
            to: "private var compactIdentityFieldsPanel"
        )
        #expect(expressionSource.contains("Menu {"))
        #expect(expressionSource.contains("Text(\"记忆表达主体\")"))
        #expect(
            expressionSource.contains(
                "expressionSubjectSelectionTitle"
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
        #expect(expressionSource.contains("默认 · 对象名称"))
        #expect(expressionSource.contains("expressionSubjectResolution.source"))
        #expect(expressionSource.contains("source.displayTitle"))
        #expect(expressionSource.contains("未填写"))
        #expect(expressionSource.contains("chevron.up.chevron.down"))
        #expect(expressionSource.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(expressionSource.contains("minimumInteractiveHeight"))
        #expect(
            editorSource.contains(
                "MemorySubject.resolveExpressionSubject("
            )
        )
    }

    @Test("basic information uses one continuous four-row Contacts-style form")
    func basicInformationUsesContinuousContactsStyleForm() throws {
        let editorSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let panelSource = try sourceSection(
            in: editorSource,
            from: "private var compactIdentityFieldsPanel",
            to: "private func contactTextField"
        )
        let fieldSource = try sourceSection(
            in: editorSource,
            from: "private func contactTextField",
            to: "private var expressionSubjectDisplayValue"
        )
        let normalizedPanel = panelSource.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        let normalizedField = fieldSource.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )

        #expect(normalizedPanel.contains("contactTextField( \"对象名称\""))
        #expect(normalizedPanel.contains("contactTextField( \"昵称\""))
        #expect(normalizedPanel.contains("contactTextField( \"与我的关系\""))
        #expect(normalizedPanel.contains("contactTextField( \"专属称呼\""))
        #expect(normalizedPanel.contains("isRequired: true"))

        #expect(fieldSource.contains(".textFieldStyle(.plain)"))
        #expect(normalizedField.contains("HStack(spacing: 8)"))
        #expect(normalizedField.contains("contactFieldPrompt( title: title, isRequired: isRequired )"))
        #expect(normalizedField.contains("Text(\"*\") .foregroundStyle(.red)"))
        #expect(normalizedField.contains("SubjectIdentityMetrics.contactFieldRowHeight"))
        #expect(normalizedField.contains("if !text.wrappedValue.isEmpty"))
        #expect(normalizedField.contains("Image(systemName: \"xmark.circle.fill\")"))
        #expect(normalizedField.contains(".accessibilityLabel(\"清除\\(title)\")"))
        #expect(normalizedField.contains("isRequired ? \"\\(title)，必填\" : title"))
        #expect(!normalizedField.contains("configurationFieldChrome"))
        #expect(!panelSource.contains("RoundedRectangle("))
    }

    @Test("subject editor centers native avatar actions above the form")
    func subjectEditorCentersNativeAvatarActionsAboveForm() throws {
        let editorSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let overviewSource = try sourceSection(
            in: editorSource,
            from: "private var identityOverviewEditor",
            to: "private var expressionSubjectCard"
        )

        #expect(overviewSource.contains("contactAvatarEditor"))
        #expect(overviewSource.contains("expressionSubjectCard"))
        #expect(overviewSource.contains("compactIdentityFieldsPanel"))
        #expect(overviewSource.contains("PhotosPicker("))
        #expect(overviewSource.contains("hasAvatar ? \"编辑\" : \"添加照片\""))
        #expect(overviewSource.contains("Image(systemName: \"minus\")"))
        #expect(overviewSource.contains("removeAvatarFromDraft()"))
        #expect(overviewSource.contains("accessibilityLabel(\"删除对象头像\")"))
        #expect(overviewSource.contains(".disabled(isOptimizingAvatar)"))
        #expect(!overviewSource.contains("adaptiveIdentityOverviewHeader"))
        #expect(!overviewSource.contains("identityOverviewText"))
        #expect(!overviewSource.contains("来自“对象名称”"))
    }

    @Test("object name is visibly required and first run reports an empty value")
    func objectNameIsRequiredAcrossEditingAndFirstRun() throws {
        let editorSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let flowSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift"
        )
        let welcomeSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1WelcomePresentation.swift"
        )

        #expect(editorSource.contains("Text(\"*\")"))
        #expect(flowSource.contains("showsNameRequiredAlert = true"))
        #expect(flowSource.contains("对象名称是保存记忆对象的必填信息。"))
        #expect(welcomeSource.contains("Text(\"*\")"))
        #expect(welcomeSource.contains("showsNameRequiredAlert"))
        #expect(welcomeSource.contains("填写对象名称"))
        #expect(welcomeSource.contains("guard hasValidSubjectName else"))
        #expect(!welcomeSource.contains("!isFirstRunConfigurationReady || isSaving"))
    }

    @Test("full Configuration Center editing does not persist a blank object name")
    func fullConfigurationCenterEditingDoesNotPersistBlankObjectName() throws {
        let editorSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let identityEditorSource = try sourceSection(
            in: editorSource,
            from: "private var identityEditor",
            to: "private var identityOverviewEditor"
        )
        let syncSource = try sourceSection(
            in: editorSource,
            from: "private func syncDraftToSession",
            to: "private var hasAvatar"
        )

        #expect(identityEditorSource.contains("Text(\"对象名称不能为空\")"))
        #expect(syncSource.contains("hasValidObjectName"))
        #expect(
            syncSource.contains(
                "guard mode != .full || hasValidObjectName else"
            )
        )
    }

    @Test("Memory Subject source names match the four visible identity fields")
    func expressionSubjectSourceNamesMatchVisibleIdentityFields() {
        #expect(MemorySubjectExpressionSubjectSource.displayName.displayTitle == "对象名称")
        #expect(MemorySubjectExpressionSubjectSource.shortName.displayTitle == "昵称")
        #expect(MemorySubjectExpressionSubjectSource.relationshipRole.displayTitle == "与我的关系")
        #expect(MemorySubjectExpressionSubjectSource.relationshipLabel.displayTitle == "专属称呼")
    }

    @Test("time anchor types provide one compact list label without losing full names")
    func timeAnchorTypesProvideCompactListLabels() {
        #expect(AnchorType.birthday.compactDisplayName(for: .simplifiedChinese) == "生日/出生")
        #expect(AnchorType.relationship.compactDisplayName(for: .simplifiedChinese) == "恋爱")
        #expect(AnchorType.marriage.compactDisplayName(for: .simplifiedChinese) == "结婚")
        #expect(AnchorType.exam.compactDisplayName(for: .simplifiedChinese) == "目标")
        #expect(AnchorType.custom.compactDisplayName(for: .simplifiedChinese) == "自定义")

        #expect(AnchorType.birthday.compactDisplayName(for: .english) == "Birthday/Birth")
        #expect(AnchorType.relationship.compactDisplayName(for: .english) == "Love")
        #expect(AnchorType.marriage.compactDisplayName(for: .english) == "Marriage")
        #expect(AnchorType.exam.compactDisplayName(for: .english) == "Goal")
        #expect(AnchorType.custom.compactDisplayName(for: .english) == "Custom")

        #expect(AnchorType.birthday.displayName == "生日 / 出生")
        #expect(AnchorType.exam.displayName == "未来目标 / 高考 / 毕业")
    }

    @Test("subject overview facts use contact-style horizontal rows")
    func subjectOverviewFactsUseContactStyleHorizontalRows() throws {
        let overviewSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSheetSurface.swift"
        )
        let factRow = try sourceSection(
            in: overviewSource,
            from: "private struct V1IOSSubjectFactRow",
            to: "#endif"
        )
        let normalizedFactRow = factRow.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )

        #expect(
            normalizedFactRow.contains(
                "HStack(alignment: .firstTextBaseline, spacing: 12)"
            )
        )
        #expect(
            normalizedFactRow.contains(
                "Text(title) .font(.body) .foregroundStyle(.secondary)"
            )
        )
        #expect(normalizedFactRow.contains("Spacer(minLength: 0)"))
        #expect(
            normalizedFactRow.contains(
                "Text(value) .font(.body) .foregroundStyle(.primary) .multilineTextAlignment(.trailing)"
            )
        )
        #expect(!normalizedFactRow.contains("VStack(alignment: .leading, spacing: 4)"))
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
