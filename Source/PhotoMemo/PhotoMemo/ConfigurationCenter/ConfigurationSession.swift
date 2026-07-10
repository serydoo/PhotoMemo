#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Combine

@MainActor
final class ConfigurationSession:
    ObservableObject {

    @Published
    var state: ConfigurationCenterState

    @Published
    private var presentationState:
        ConfigurationSessionPresentationState
        = .init()

    private static let maximumMemoryPresetTitleLength = 24

    init(
        state: ConfigurationCenterState? = nil
    ) {
        let resolvedState = state ?? .mock
        self.state = resolvedState
        self.presentationState =
            ConfigurationSessionPresentationState(
                appliedMemoryPresetID:
                    resolvedState
                    .selectedMemoryPreset?
                    .id
            )
        alignSelectedMemoryPresetToSelectedSubject(
            restoreContext: true
        )
    }

    var selectedOutputOption:
        ConfigurationOutputOption {
        get {
            presentationState
                .selectedOutputOption
        }
        set {
            presentationState
                .selectedOutputOption = newValue
            markSelectedMemoryPresetNeedsApply()
        }
    }

    var selectedStorageOption:
        ConfigurationStorageOption {
        get {
            presentationState
                .selectedStorageOption
        }
        set {
            presentationState
                .selectedStorageOption = newValue
            markSelectedMemoryPresetNeedsApply()
        }
    }

    var usesCustomMemoryWriteText: Bool {
        get {
            presentationState
                .usesCustomMemoryWriteText
        }
        set {
            presentationState
                .usesCustomMemoryWriteText = newValue
            markSelectedMemoryPresetNeedsApply()
        }
    }

    var customMemoryWriteText: String {
        get {
            presentationState
                .customMemoryWriteText
        }
        set {
            presentationState
                .customMemoryWriteText = newValue
            markSelectedMemoryPresetNeedsApply()
        }
    }

    var latestModuleInsertion:
        MemoryModuleInsertion? {
        get {
            presentationState
                .latestModuleInsertion
        }
        set {
            presentationState
                .latestModuleInsertion = newValue
        }
    }

    var appliedMemoryPresetID:
        MemoryPreset.ID? {
        get {
            presentationState
                .appliedMemoryPresetID
        }
        set {
            presentationState
                .appliedMemoryPresetID = newValue
        }
    }

    func selectSubject(
        _ subject: MemorySubject
    ) {
        let previousSubject = state.selectedSubject
        let previousDefaultMemory =
            Self.defaultPreviewText(
                for: .slotD,
                subject: previousSubject
            )

        state.selectedSubjectID = subject.id
        state.regionPreviewTexts[.subject] =
            Self.defaultPreviewText(
                for: .subject,
                subject: subject
            )

        if state.regionPreviewTexts[.slotD] == nil
            || state.regionPreviewTexts[.slotD] == previousDefaultMemory {
            state.regionPreviewTexts[.slotD] =
                Self.defaultPreviewText(
                    for: .slotD,
                    subject: subject
                )
        }
        selectRegion(.subject)
        markSelectedMemoryPresetNeedsApply()
        alignSelectedMemoryPresetToSelectedSubject(
            restoreContext: true
        )
    }

    func selectRegion(
        _ region: CardRegion
    ) {
        select(
            CardRegionBehavior(region: region)
        )
    }

    func select(
        _ behavior: CardRegionBehavior
    ) {
        state.cardSelection.select(behavior.region)
    }

    func hoverRegion(
        _ region: CardRegion?
    ) {
        state.cardSelection.hover(region)
    }

    func selectBlock(
        _ block: MemoryBlock
    ) {
        state.selectedBlockID = block.id
    }

    func updateSelectedSubject(
        _ subject: MemorySubject
    ) {
        let previousSubject = state.selectedSubject
        let previousDefaultMemory =
            Self.defaultPreviewText(
                for: .slotD,
                subject: previousSubject
            )

        guard
            let subjectIndex =
                state.subjects.firstIndex(
                    where: { $0.id == subject.id }
                )
        else {
            return
        }

        state.subjects[subjectIndex] = subject
        state.selectedSubjectID = subject.id
        state.regionPreviewTexts[.subject] =
            Self.defaultPreviewText(
                for: .subject,
                subject: subject
            )

        if state.regionPreviewTexts[.slotD] == nil
            || state.regionPreviewTexts[.slotD] == previousDefaultMemory {
            state.regionPreviewTexts[.slotD] =
                Self.defaultPreviewText(
                    for: .slotD,
                    subject: subject
                )
        }
        markSelectedMemoryPresetNeedsApply()
    }

    func restoreSelectedSubject(
        _ subject: MemorySubject
    ) {
        let previousSubject = state.selectedSubject
        let previousDefaultMemory =
            Self.defaultPreviewText(
                for: .slotD,
                subject: previousSubject
            )

        if let subjectIndex =
            state.subjects.firstIndex(
                where: { $0.id == subject.id }
            ) {
            state.subjects[subjectIndex] = subject
        } else if let selectedSubjectID =
            state.selectedSubjectID,
                  let selectedIndex =
                    state.subjects.firstIndex(
                        where: {
                            $0.id == selectedSubjectID
                        }
                    ) {
            state.subjects[selectedIndex] = subject
        } else if !state.subjects.isEmpty {
            state.subjects[0] = subject
        } else {
            state.subjects = [subject]
        }

        state.selectedSubjectID = subject.id
        state.regionPreviewTexts[.subject] =
            Self.defaultPreviewText(
                for: .subject,
                subject: subject
            )

        if state.regionPreviewTexts[.slotD] == nil
            || state.regionPreviewTexts[.slotD] == previousDefaultMemory {
            state.regionPreviewTexts[.slotD] =
                Self.defaultPreviewText(
                    for: .slotD,
                    subject: subject
                )
        }
    }

    func restoreSubjectLibrary(
        _ subjects: [MemorySubject],
        selectedSubjectID: MemorySubject.ID?,
        memoryPresets: [MemoryPreset]? = nil,
        selectedMemoryPresetID: MemoryPreset.ID? = nil
    ) {
        guard !subjects.isEmpty else {
            return
        }

        let previousSubject = state.selectedSubject
        let previousDefaultMemory =
            Self.defaultPreviewText(
                for: .slotD,
                subject: previousSubject
            )

        state.subjects = subjects
        state.selectedSubjectID =
            subjects.contains {
                $0.id == selectedSubjectID
            }
            ? selectedSubjectID
            : subjects.first?.id

        if let memoryPresets {
            state.memoryPresets = memoryPresets
            state.selectedMemoryPresetID =
                memoryPresets.contains {
                    $0.id == selectedMemoryPresetID
                }
                ? selectedMemoryPresetID
                : memoryPresets.first {
                    $0.selectedSubjectID == state.selectedSubjectID
                }?.id
        }

        let selectedSubject =
            state.selectedSubject

        state.regionPreviewTexts[.subject] =
            Self.defaultPreviewText(
                for: .subject,
                subject: selectedSubject
            )

        if state.regionPreviewTexts[.slotD] == nil
            || state.regionPreviewTexts[.slotD] == previousDefaultMemory {
            state.regionPreviewTexts[.slotD] =
                Self.defaultPreviewText(
                    for: .slotD,
                    subject: selectedSubject
                )
        }

        alignSelectedMemoryPresetToSelectedSubject(
            restoreContext: true
        )
    }

    func appendSubject(
        _ subject: MemorySubject,
        selectAfterInsert: Bool = true
    ) {
        state.subjects.append(subject)

        guard selectAfterInsert else {
            return
        }

        selectSubject(subject)
    }

    func removeSubject(
        id: MemorySubject.ID
    ) {
        guard
            state.subjects.count > 1,
            let subjectIndex =
                state.subjects.firstIndex(
                    where: { $0.id == id }
                )
        else {
            return
        }

        let previousSubject = state.selectedSubject
        let previousDefaultMemory =
            Self.defaultPreviewText(
                for: .slotD,
                subject: previousSubject
            )

        state.subjects.remove(at: subjectIndex)

        let selectedSubjectStillExists: Bool

        if let selectedSubjectID =
            state.selectedSubjectID {
            selectedSubjectStillExists =
                state.subjects.contains {
                    $0.id == selectedSubjectID
                }
        } else {
            selectedSubjectStillExists = false
        }

        if state.selectedSubjectID == id
            || !selectedSubjectStillExists {
            let fallbackIndex =
                min(subjectIndex, state.subjects.count - 1)
            state.selectedSubjectID =
                state.subjects[fallbackIndex].id
        }

        let selectedSubject =
            state.selectedSubject

        state.regionPreviewTexts[.subject] =
            Self.defaultPreviewText(
                for: .subject,
                subject: selectedSubject
            )

        if state.regionPreviewTexts[.slotD] == nil
            || state.regionPreviewTexts[.slotD] == previousDefaultMemory {
            state.regionPreviewTexts[.slotD] =
                Self.defaultPreviewText(
                    for: .slotD,
                    subject: selectedSubject
                )
        }

        alignSelectedMemoryPresetToSelectedSubject(
            restoreContext: true
        )
    }

    func updateRegionPreview(
        region: CardRegion,
        text: String
    ) {
        state.regionPreviewTexts[region] = text
    }

    func appendPreviewModule(
        title: String,
        value: String,
        systemImage: String = "tag.fill",
        token: String? = nil
    ) {
        let region = state.selectedRegion
        guard CardRegion.memoryCardRegions.contains(region) else {
            return
        }

        let current =
            previewText(for: region)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let insertion =
            value.trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
            ? title
            : value

        let nextText =
            InlineContentTextComposer.compose([
                InlineContentTextComposer.Piece(
                    kind: .text,
                    value: current
                ),
                InlineContentTextComposer.Piece(
                    kind: .token,
                    value: insertion
                )
            ])

        updateRegionPreview(
            region: region,
            text: nextText
        )

        latestModuleInsertion =
            MemoryModuleInsertion(
                region: region,
                title: title,
                value: insertion,
                systemImage: systemImage,
                token: token ?? title
            )
    }

    var currentOutputPreview: String {
        previewText(
            for: state.selectedRegion
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .isEmpty
        ? "当前区域暂无输出"
        : previewText(for: state.selectedRegion)
    }

    var smartModuleCarrierRegion: CardRegion {
        CardRegion.memoryCardRegions.contains(
            state.selectedRegion
        )
        ? state.selectedRegion
        : .slotD
    }

    var currentConfigurationSnapshot:
        ConfigurationSnapshot? {
        ConfigurationSnapshotBuilder
            .build(from: self)
    }

    var generatedMemoryModule: MemoryModule? {
        guard
            let snapshot =
                currentConfigurationSnapshot,
            let subject =
                state.selectedSubject
        else {
            return nil
        }

        let context =
            MemoryExpressionContext(
                subject: subject,
                snapshot: snapshot,
                captureDate:
                    MemoryExpressionPreviewResolver
                    .defaultCaptureDate
            )

        let result =
            MemoryExpressionEngine()
            .generateResult(
                context: context
            )

        return MemoryResultPresentationAdapter()
            .makeModule(
                result: result,
                context: context
            )
    }

    var resolvedMemoryWriteText: String {
        let customText =
            customMemoryWriteText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if usesCustomMemoryWriteText,
           !customText.isEmpty {
            return customText
        }

        let memoryText =
            generatedMemoryModule?
            .renderedText
            ?? generatedMemoryModuleText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return memoryText.isEmpty
        ? "当前智能模块暂无内容"
        : memoryText
    }

    var generatedMemoryModuleText: String {
        generatedMemoryModule?
            .renderedText
        ?? Self.generatedMemoryModuleText(
            subject: state.selectedSubject,
            smartModuleCarrierRegion:
                smartModuleCarrierRegion
        ) ?? ""
    }

    func selectMemoryPreset(
        _ preset: MemoryPreset
    ) {
        state.selectedMemoryPresetID = preset.id
        restoreConfigurationContext(
            from: state.selectedMemoryPreset ?? preset
        )
        appliedMemoryPresetID =
            state.selectedMemoryPreset?.id
            ?? preset.id
        refreshPresetDrivenPreview()
    }

    func saveCurrentMemoryPreset(
        logoMode: V1LogoMode? = nil,
        outputConfiguration:
            V1SavedOutputConfiguration? = nil
    ) {
        guard let presetIndex =
            writableSelectedMemoryPresetIndex()
        else {
            createMemoryPresetFromCurrent(
                savedAt: Date(),
                applyImmediately: true,
                logoMode: logoMode,
                outputConfiguration:
                    outputConfiguration
            )
            return
        }

        state.memoryPresets[presetIndex] =
            snapshotCurrentConfiguration(
                in: state.memoryPresets[presetIndex],
                savedAt: Date(),
                logoMode: logoMode,
                outputConfiguration:
                    outputConfiguration
            )
        state.selectedMemoryPresetID =
            state.memoryPresets[presetIndex].id
        appliedMemoryPresetID =
            state.memoryPresets[presetIndex].id
    }

    func createMemoryPresetFromCurrent(
        logoMode: V1LogoMode? = nil,
        outputConfiguration:
            V1SavedOutputConfiguration? = nil
    ) {
        createMemoryPresetFromCurrent(
            savedAt: nil,
            applyImmediately: false,
            logoMode: logoMode,
            outputConfiguration:
                outputConfiguration
        )
    }

    private func createMemoryPresetFromCurrent(
        savedAt: Date?,
        applyImmediately: Bool,
        logoMode: V1LogoMode?,
        outputConfiguration:
            V1SavedOutputConfiguration?
    ) {
        let duplicatedPreset =
            snapshotCurrentConfiguration(
                in: MemoryPreset(
                    title:
                        currentDefaultMemoryPresetTitle,
                    summary:
                        state.selectedMemoryPreset?
                        .summary
                        ?? "当前区域组合",
                    regionTemplateIDs:
                        currentRegionTemplateIDs
                ),
                savedAt: savedAt,
                logoMode: logoMode,
                outputConfiguration:
                    outputConfiguration
            )

        state.memoryPresets.append(
            duplicatedPreset
        )
        state.selectedMemoryPresetID =
            duplicatedPreset.id
        appliedMemoryPresetID =
            applyImmediately
            ? duplicatedPreset.id
            : nil
        refreshPresetDrivenPreview()
    }

    @discardableResult
    func deleteSelectedMemoryPreset() -> Bool {
        guard let presetIndex =
            writableSelectedMemoryPresetIndex()
        else {
            return false
        }

        let deletedPresetID =
            state.memoryPresets[presetIndex].id

        state.memoryPresets.remove(
            at: presetIndex
        )

        if appliedMemoryPresetID == deletedPresetID {
            appliedMemoryPresetID = nil
        }

        alignSelectedMemoryPresetToSelectedSubject(
            restoreContext: true
        )
        return true
    }

    func persistenceSnapshotForCurrentConfiguration(
        logoMode: V1LogoMode? = nil,
        outputConfiguration:
            V1SavedOutputConfiguration? = nil,
        savedAt: Date = Date()
    ) -> (
        memoryPresets: [MemoryPreset],
        selectedMemoryPresetID: MemoryPreset.ID
    ) {
        if let presetIndex =
            writableSelectedMemoryPresetIndex() {
            var memoryPresets =
                state.memoryPresets
            let selectedPreset =
                snapshotCurrentConfiguration(
                    in:
                        memoryPresets[presetIndex],
                    savedAt: savedAt,
                    logoMode: logoMode,
                    outputConfiguration:
                        outputConfiguration
                )
            memoryPresets[presetIndex] =
                selectedPreset
            return (
                memoryPresets,
                selectedPreset.id
            )
        }

        let selectedPreset =
            snapshotCurrentConfiguration(
                in: MemoryPreset(
                    title:
                        currentDefaultMemoryPresetTitle,
                    summary:
                        state.selectedMemoryPreset?
                        .summary
                        ?? "当前区域组合",
                    regionTemplateIDs:
                        currentRegionTemplateIDs
                ),
                savedAt: savedAt,
                logoMode: logoMode,
                outputConfiguration:
                    outputConfiguration
            )
        return (
            state.memoryPresets + [selectedPreset],
            selectedPreset.id
        )
    }

    func updateSelectedMemoryPresetTitle(
        _ title: String
    ) {
        guard let presetIndex = selectedMemoryPresetIndex else {
            return
        }

        let trimmed =
            title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTitle =
            String(
                trimmed.prefix(Self.maximumMemoryPresetTitleLength)
            )

        var updatedState = state
        updatedState.memoryPresets[presetIndex].title =
            normalizedTitle.isEmpty
            ? "记忆预设"
            : normalizedTitle
        state = updatedState
        markSelectedMemoryPresetNeedsApply()
    }

    func updateActiveTemplate(
        for region: CardRegion,
        templateID: String
    ) {
        guard let presetIndex = selectedMemoryPresetIndex else {
            return
        }

        state.memoryPresets[presetIndex]
            .regionTemplateIDs[region] = templateID
        markSelectedMemoryPresetNeedsApply()
    }

    func activeTemplateID(
        for region: CardRegion
    ) -> String? {
        state.selectedMemoryPreset?
            .templateID(for: region)
    }

    var currentMemoryPresetTitle: String {
        guard
            !availableMemoryPresetsForSelectedSubject.isEmpty
        else {
            return "当前对象还没有配置"
        }

        return state.selectedMemoryPreset?.title ?? "记忆预设"
    }

    var currentMemoryPresetSummary: String {
        guard
            !availableMemoryPresetsForSelectedSubject.isEmpty
        else {
            return "为当前记忆对象新建配置后即可使用。"
        }

        return state.selectedMemoryPreset?.summary ?? "当前区域组合"
    }

    var selectedMemoryPresetIsApplied: Bool {
        guard let selectedPresetID = state.selectedMemoryPreset?.id else {
            return false
        }

        return appliedMemoryPresetID == selectedPresetID
    }

    var availableMemoryPresetsForSelectedSubject:
        [MemoryPreset] {
        guard let selectedSubjectID =
            state.selectedSubject?.id
        else {
            return state.memoryPresets
        }

        return state.memoryPresets.filter {
            $0.selectedSubjectID == selectedSubjectID
        }
    }

    func applySelectedMemoryPreset() {
        appliedMemoryPresetID = state.selectedMemoryPreset?.id
    }

    func resetSelectedMemoryPreset() {
        refreshPresetDrivenPreview()
        latestModuleInsertion = nil
        markSelectedMemoryPresetNeedsApply()
    }

    var currentConfigurationLabel: String {
        let subjectName =
            state.selectedSubject?.identity.displayName
            ?? "记忆对象"

        let anchorName =
            state.selectedSubject?
            .primaryTimeAnchor?
            .title
            ?? state.selectedSubject?
            .behavior.primaryAnchor
            ?? "自定义时间"

        return "\(subjectName) · \(anchorName)"
    }

    var currentDefaultMemoryPresetTitle: String {
        let subjectName =
            state.selectedSubject?
            .identity
            .displayName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        let anchorName =
            currentTimeAnchorTitle
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let rawTitle =
            [
                subjectName?.isEmpty == false
                ? subjectName
                : nil,
                anchorName.isEmpty ? nil : anchorName
            ]
            .compactMap { $0 }
            .joined(separator: " ")
        let normalizedTitle =
            rawTitle.isEmpty
            ? "记忆预设"
            : rawTitle

        return String(
            normalizedTitle
                .prefix(
                    Self.maximumMemoryPresetTitleLength
                )
        )
    }

    var currentTimeAnchorTitle: String {
        state.selectedSubject?
        .primaryTimeAnchor?
        .title
        ?? state.selectedSubject?
        .behavior.primaryAnchor
        ?? "时间锚点"
    }

    var availableTimeAnchors:
        [MemorySubject.TimeAnchor] {
        state.selectedSubject?.timeAnchors ?? []
    }

    var selectedTimeAnchorID: UUID? {
        state.selectedSubject?.primaryTimeAnchor?.id
    }

    func selectTimeAnchor(
        id: UUID
    ) {
        guard
            var subject = state.selectedSubject,
            let selectedAnchor =
                subject.timeAnchor(id: id)
        else {
            return
        }

        subject.activeTimeAnchorID =
            selectedAnchor.id
        subject.behavior.primaryAnchor =
            selectedAnchor.title
        subject.referenceDate =
            selectedAnchor.date
        updateSelectedSubject(subject)
    }

    func selectCurrentTimeAnchorExpressionStyle(
        _ style: MemoryAnchorExpressionStyle
    ) {
        guard
            var subject = state.selectedSubject,
            let selectedAnchorID =
                subject.primaryTimeAnchor?.id,
            let anchorIndex =
                subject.timeAnchors.firstIndex(
                    where: { $0.id == selectedAnchorID }
                )
        else {
            return
        }

        subject.timeAnchors[anchorIndex]
            .expressionStyle = style
        updateSelectedSubject(subject)
    }

    var currentTimeAnchorDescription: String {
        guard let subject = state.selectedSubject else {
            return "锚点说明"
        }

        let anchor =
            subject.primaryTimeAnchor

        if let note = anchor?.note,
           !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return note
        }

        let subjectName =
            subject.identity.shortName.isEmpty
            ? subject.identity.displayName
            : subject.identity.shortName

        return "\(subjectName)\(anchor?.title ?? "时间锚点")"
    }

    func previewText(
        for region: CardRegion
    ) -> String {
        state.regionPreviewTexts[region]
        ?? Self.defaultPreviewText(
            for: region,
            subject: state.selectedSubject
        )
    }

    func insertBlock(
        _ block: MemoryBlock
    ) {
        guard let subjectIndex = selectedSubjectIndex else {
            return
        }

        state.subjects[subjectIndex]
            .behavior.memoryExpression.blocks
            .append(block)
    }

    func removeBlock(
        _ block: MemoryBlock
    ) {
        guard let subjectIndex = selectedSubjectIndex else {
            return
        }

        state.subjects[subjectIndex]
            .behavior.memoryExpression.blocks
            .removeAll {
                $0.id == block.id
            }
    }

    func moveBlock(
        _ block: MemoryBlock,
        direction: Int
    ) {
        guard let subjectIndex = selectedSubjectIndex else {
            return
        }

        var blocks =
            state.subjects[subjectIndex]
            .behavior.memoryExpression.blocks

        guard
            let currentIndex =
                blocks.firstIndex(where: {
                    $0.id == block.id
                })
        else {
            return
        }

        let targetIndex =
            min(
                max(currentIndex + direction, 0),
                blocks.count - 1
            )

        guard currentIndex != targetIndex else {
            return
        }

        let movedBlock =
            blocks.remove(at: currentIndex)
        blocks.insert(
            movedBlock,
            at: targetIndex
        )
        state.subjects[subjectIndex]
            .behavior.memoryExpression.blocks = blocks
        state.selectedBlockID = block.id
    }

    func selectDecoration(
        _ decoration: DecorationAsset
    ) {
        guard let subjectIndex = selectedSubjectIndex else {
            return
        }

        state.subjects[subjectIndex]
            .decorations
            .removeAll {
                $0.kind == decoration.kind
            }
        state.subjects[subjectIndex]
            .decorations
            .append(decoration)
    }

    private func refreshSubjectDrivenPreview() {
        if state.regionPreviewTexts[.slotD] == nil {
            state.regionPreviewTexts[.slotD] =
                Self.defaultPreviewText(
                    for: .slotD,
                    subject: state.selectedSubject
                )
        }
    }

    private func refreshPresetDrivenPreview() {
        for region in CardRegion.memoryCardRegions {
            let templateID =
                activeTemplateID(for: region)

            state.regionPreviewTexts[region] =
                Self.defaultPreviewText(
                    for: region,
                    templateID: templateID,
                    subject: state.selectedSubject
                )
        }
    }

    private func markSelectedMemoryPresetNeedsApply() {
        guard selectedMemoryPresetIsApplied else {
            return
        }

        appliedMemoryPresetID = nil
    }

    private func snapshotCurrentConfiguration(
        in preset: MemoryPreset,
        savedAt: Date?,
        logoMode: V1LogoMode?,
        outputConfiguration:
            V1SavedOutputConfiguration?
    ) -> MemoryPreset {
        var updatedPreset = preset
        updatedPreset.savedAt = savedAt
        updatedPreset.selectedSubjectID =
            state.selectedSubject?.id
        updatedPreset.selectedTimeAnchorID =
            state.selectedSubject?
            .primaryTimeAnchor?
            .id
        updatedPreset.outputOption =
            selectedOutputOption
        updatedPreset.storageOption =
            selectedStorageOption
        updatedPreset.logoMode =
            logoMode
            ?? preset.logoMode
        updatedPreset.usesCustomMemoryWriteText =
            usesCustomMemoryWriteText
        updatedPreset.customMemoryWriteText =
            customMemoryWriteText
        updatedPreset.savedOutputConfiguration =
            outputConfiguration
            ?? preset.savedOutputConfiguration
        return updatedPreset
    }

    private func restoreConfigurationContext(
        from preset: MemoryPreset
    ) {
        if let subjectID = preset.selectedSubjectID,
           let subjectIndex =
            state.subjects.firstIndex(where: {
                $0.id == subjectID
            }) {
            var restoredSubject =
                state.subjects[subjectIndex]

            if let anchorID =
                preset.selectedTimeAnchorID,
               let anchor =
                restoredSubject.timeAnchor(id: anchorID) {
                restoredSubject.activeTimeAnchorID =
                    anchor.id
                restoredSubject.behavior.primaryAnchor =
                    anchor.title
                restoredSubject.referenceDate =
                    anchor.date
            }

            restoreSelectedSubject(
                restoredSubject
            )
        }

        restorePresentationContext(
            from: preset
        )
    }

    private func restorePresentationContext(
        from preset: MemoryPreset
    ) {
        presentationState.selectedOutputOption =
            preset.outputOption
        presentationState.selectedStorageOption =
            preset.storageOption
        presentationState.usesCustomMemoryWriteText =
            preset.usesCustomMemoryWriteText
        presentationState.customMemoryWriteText =
            preset.customMemoryWriteText
    }

    private func alignSelectedMemoryPresetToSelectedSubject(
        restoreContext: Bool
    ) {
        guard let preset =
            preferredMemoryPresetForSelectedSubject
        else {
            state.selectedMemoryPresetID = nil
            appliedMemoryPresetID = nil
            refreshPresetDrivenPreview()
            return
        }

        state.selectedMemoryPresetID = preset.id

        guard restoreContext else {
            return
        }

        restoreConfigurationContext(
            from: preset
        )
        refreshPresetDrivenPreview()
    }

    static func defaultPreviewText(
        for region: CardRegion,
        subject: MemorySubject?
    ) -> String {
        ConfigurationCenterPreviewDefaults
            .defaultPreviewText(
                for: region,
                subject: subject
            )
    }

    static func defaultPreviewText(
        for region: CardRegion,
        templateID: String?,
        subject: MemorySubject?
    ) -> String {
        ConfigurationCenterPreviewDefaults
            .defaultPreviewText(
                for: region,
                templateID: templateID,
                subject: subject
            )
    }

    private static func generatedMemoryModuleText(
        subject: MemorySubject?,
        smartModuleCarrierRegion: CardRegion = .slotD
    ) -> String? {
        ConfigurationCenterPreviewDefaults
            .generatedMemoryModuleText(
                subject: subject,
                smartModuleCarrierRegion:
                    smartModuleCarrierRegion
            )
    }

    private var selectedSubjectIndex: Int? {
        guard let subject = state.selectedSubject else {
            return nil
        }

        return state.subjects.firstIndex {
            $0.id == subject.id
        }
    }

    private var selectedMemoryPresetIndex: Int? {
        guard let preset = state.selectedMemoryPreset else {
            return nil
        }

        return state.memoryPresets.firstIndex {
            $0.id == preset.id
        }
    }

    private func writableSelectedMemoryPresetIndex() -> Int? {
        guard
            let presetIndex = selectedMemoryPresetIndex
        else {
            return nil
        }

        let selectedSubjectID =
            state.selectedSubject?.id
        let presetSubjectID =
            state.memoryPresets[presetIndex]
            .selectedSubjectID

        guard presetSubjectID == nil
            || presetSubjectID == selectedSubjectID else {
            return nil
        }

        return presetIndex
    }

    private var currentRegionTemplateIDs:
        [CardRegion: String] {

        if let selectedPreset =
            state.selectedMemoryPreset {
            return selectedPreset.regionTemplateIDs
        }

        return ConfigurationCenterMockSeed
            .makeState()
            .memoryPresets
            .first?
            .regionTemplateIDs
        ?? [:]
    }

    private var preferredMemoryPresetForSelectedSubject:
        MemoryPreset? {
        let presets =
            availableMemoryPresetsForSelectedSubject

        guard !presets.isEmpty else {
            return nil
        }

        if let selectedMemoryPresetID =
            state.selectedMemoryPresetID,
           let selectedPreset =
            presets.first(where: {
                $0.id == selectedMemoryPresetID
            }) {
            return selectedPreset
        }

        if let appliedMemoryPresetID,
           let appliedPreset =
            presets.first(where: {
                $0.id == appliedMemoryPresetID
            }) {
            return appliedPreset
        }

        if let latestSavedPreset =
            presets
            .filter({ $0.savedAt != nil })
            .max(by: { lhs, rhs in
                (lhs.savedAt ?? .distantPast)
                < (rhs.savedAt ?? .distantPast)
            }) {
            return latestSavedPreset
        }

        return presets.first
    }
}

struct MemoryModuleInsertion:
    Identifiable,
    Hashable {

    let id: UUID
    let region: CardRegion
    let title: String
    let value: String
    let systemImage: String
    let token: String

    init(
        id: UUID = UUID(),
        region: CardRegion,
        title: String,
        value: String,
        systemImage: String,
        token: String
    ) {
        self.id = id
        self.region = region
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.token = token
    }
}

enum ConfigurationOutputOption:
    String,
    Codable,
    CaseIterable,
    Identifiable {

    case processedImage

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .processedImage:
            return "处理过的图片"
        }
    }

    var note: String {
        switch self {
        case .processedImage:
            return "生成新图片，不修改原始照片。"
        }
    }
}

enum ConfigurationStorageOption:
    String,
    Codable,
    CaseIterable,
    Identifiable {

    case appFolder
    case existingFolder
    case newFolder
    case targetAlbum

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .appFolder:
            return "时光记文件夹"
        case .existingFolder:
            return "现有文件夹"
        case .newFolder:
            return "新建文件夹"
        case .targetAlbum:
            return "目标相册"
        }
    }

    var note: String {
        switch self {
        case .appFolder:
            return "未指定保存地点时，默认存入软件对应的时光记文件夹。"
        case .existingFolder:
            return "后续从已有文件夹中选择保存位置。"
        case .newFolder:
            return "后续新建文件夹并保存本次输出。"
        case .targetAlbum:
            return "后续写入指定 Apple Photos 相册。"
        }
    }
}
#endif
