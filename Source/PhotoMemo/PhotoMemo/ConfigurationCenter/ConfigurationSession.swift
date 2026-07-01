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

        return MemoryExpressionEngine()
            .generateModule(
                context:
                    MemoryExpressionContext(
                        subject: subject,
                        snapshot: snapshot,
                        captureDate:
                            MemoryExpressionPreviewResolver
                            .defaultCaptureDate
                    )
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
        refreshPresetDrivenPreview()
    }

    func updateSelectedMemoryPresetTitle(
        _ title: String
    ) {
        guard let presetIndex = selectedMemoryPresetIndex else {
            return
        }

        let trimmed =
            title.trimmingCharacters(in: .whitespacesAndNewlines)

        state.memoryPresets[presetIndex].title =
            trimmed.isEmpty
            ? "记忆预设"
            : trimmed
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
        state.selectedMemoryPreset?.title ?? "记忆预设"
    }

    var currentMemoryPresetSummary: String {
        state.selectedMemoryPreset?.summary ?? "当前区域组合"
    }

    var selectedMemoryPresetIsApplied: Bool {
        guard let selectedPresetID = state.selectedMemoryPreset?.id else {
            return false
        }

        return appliedMemoryPresetID == selectedPresetID
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

    var currentTimeAnchorTitle: String {
        state.selectedSubject?
        .primaryTimeAnchor?
        .title
        ?? state.selectedSubject?
        .behavior.primaryAnchor
        ?? "时间锚点"
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
            return "PhotoMemo 文件夹"
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
            return "未指定保存地点时，默认存入软件对应的 PhotoMemo 文件夹。"
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
