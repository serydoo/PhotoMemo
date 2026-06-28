#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Combine

@MainActor
final class ConfigurationSession:
    ObservableObject {

    @Published
    var state: ConfigurationCenterState

    @Published
    var selectedOutputOption: ConfigurationOutputOption = .processedImage

    @Published
    var selectedStorageOption: ConfigurationStorageOption = .appFolder

    @Published
    var usesCustomMemoryWriteText = false

    @Published
    var customMemoryWriteText = ""

    @Published
    var latestModuleInsertion: MemoryModuleInsertion?

    @Published
    var appliedMemoryPresetID: MemoryPreset.ID?

    init(
        state: ConfigurationCenterState? = nil
    ) {
        let resolvedState = state ?? .mock
        self.state = resolvedState
        self.appliedMemoryPresetID =
            resolvedState.selectedMemoryPreset?.id
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
        if behavior.region != .slotD {
            state.selectedBlockID = nil
        }
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
        state.selectedRegion = .slotD
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
            current.isEmpty
            ? insertion
            : "\(current) \(insertion)"

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

    var resolvedMemoryWriteText: String {
        let customText =
            customMemoryWriteText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if usesCustomMemoryWriteText,
           !customText.isEmpty {
            return customText
        }

        let memoryText =
            previewText(for: .slotD)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return memoryText.isEmpty
        ? "当前记忆区域暂无内容"
        : memoryText
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
            state.selectedSubject?.behavior.primaryAnchor
            ?? "自定义时间"

        return "\(subjectName) · \(anchorName)"
    }

    var currentTimeAnchorTitle: String {
        state.selectedSubject?.behavior.primaryAnchor
        ?? "时间锚点"
    }

    var currentTimeAnchorDescription: String {
        guard let subject = state.selectedSubject else {
            return "锚点说明"
        }

        let anchor =
            subject.timeAnchors.first {
                $0.title == subject.behavior.primaryAnchor
            }
            ?? subject.timeAnchors.first

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
        defaultPreviewText(
            for: region,
            templateID: nil,
            subject: subject
        )
    }

    static func defaultPreviewText(
        for region: CardRegion,
        templateID: String?,
        subject: MemorySubject?
    ) -> String {
        if let templateID,
           let text =
            defaultPreviewText(
                forTemplateID: templateID,
                subject: subject
            ) {
            return text
        }

        switch region {
        case .slotA:
            return "记录"
        case .slotB:
            return "2026.05.24 14:33:13"
        case .slotC:
            return "20mm f/1.9 1/117s ISO80"
        case .slotD:
            return subject?
                .behavior.memoryExpression.displayText
                ?? "记忆表达"
        case .subject:
            return subject?.identity.shortName
            ?? subject?.identity.displayName
            ?? "记忆对象"
        case .icon:
            return subject?
                .decorations
                .first(where: { $0.kind == .icon })?
                .title ?? "图标"
        case .badge:
            return subject?
                .decorations
                .first(where: { $0.kind == .badge })?
                .title ?? "徽标"
        }
    }

    private static func defaultPreviewText(
        forTemplateID templateID: String,
        subject: MemorySubject?
    ) -> String? {
        let subjectName =
            subject?.identity.shortName.isEmpty == false
            ? subject?.identity.shortName
            : subject?.identity.displayName

        switch templateID {
        case "recorder.configuration1":
            return "记录 iPhone 17 Pro Max"
        case "recorder.configuration2",
             "recorder.configuration3":
            return " "
        case "timeline.configuration1":
            return "2026.05.24 14:33:13"
        case "timeline.configuration2":
            return "2026.05.24"
        case "timeline.configuration3":
            return " "
        case "context.configuration1":
            return "20mm f/1.9 1/117s ISO80"
        case "context.configuration2":
            return "24mm f/1.78 1/100s ISO125"
        case "context.configuration3":
            return " "
        case "memory.configuration1":
            return "\(subjectName ?? "图图") 当天 11个月28天"
        case "memory.configuration2",
             "memory.configuration3":
            return " "
        default:
            return nil
        }
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

extension ConfigurationCenterState {

    static var mock: ConfigurationCenterState {
        let expression =
            MemoryExpression(
                title: "生日记忆",
                blocks: [
                    .text(""),
                    MemoryBlock(
                        type: .memory,
                        title: "昵称",
                        value: "昵称"
                    ),
                    .text(" 今天 "),
                    MemoryBlock(
                        type: .memory,
                        title: "年龄",
                        value: "年龄"
                    ),
                    .text(" 啦")
                ]
            )

        let icon =
            DecorationAsset(
                kind: .icon,
                title: "人物",
                systemSymbolName: "person.fill"
            )

        let badge =
            DecorationAsset(
                kind: .badge,
                title: "相机",
                systemSymbolName: "camera.fill"
            )

        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "Tutu",
                        shortName: "Tutu"
                    ),
                relationship:
                    .init(
                        role: "家庭",
                        label: "家人"
                    ),
                definition: "家庭成长记录的主要记忆对象。",
                referenceDate:
                    Calendar.current.date(
                        from:
                            DateComponents(
                                year: 2024,
                                month: 4,
                                day: 18
                            )
                    ) ?? Date(),
                timeAnchors: [
                    MemorySubject.TimeAnchor(
                        title: "生日",
                        date:
                            Calendar.current.date(
                                from:
                                    DateComponents(
                                        year: 2024,
                                        month: 4,
                                        day: 18
                                    )
                            ) ?? Date(),
                        note: "图图出生日期"
                    ),
                    MemorySubject.TimeAnchor(
                        title: "第一次旅行",
                        date:
                            Calendar.current.date(
                                from:
                                    DateComponents(
                                        year: 2025,
                                        month: 10,
                                        day: 2
                                    )
                            ) ?? Date(),
                        note: "图图第一次旅行"
                    ),
                    MemorySubject.TimeAnchor(
                        title: "入园",
                        date:
                            Calendar.current.date(
                                from:
                                    DateComponents(
                                        year: 2027,
                                        month: 9,
                                        day: 1
                                    )
                            ) ?? Date(),
                        note: "图图入园日期"
                    )
                ],
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "生日",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .fixed,
                        memoryExpression: expression
                    ),
                decorations: [
                    icon,
                    badge
                ]
            )

        let travelSubject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "Kyoto Spring",
                        shortName: "Kyoto"
                    ),
                relationship:
                    .init(
                        role: "旅行",
                        label: "旅行"
                    ),
                definition: "一次值得反复回看的旅行记忆。",
                referenceDate:
                    Calendar.current.date(
                        from:
                            DateComponents(
                                year: 2025,
                                month: 3,
                                day: 29
                            )
                    ) ?? Date(),
                timeAnchors: [
                    MemorySubject.TimeAnchor(
                        title: "出发",
                        date:
                            Calendar.current.date(
                                from:
                                    DateComponents(
                                        year: 2025,
                                        month: 3,
                                        day: 29
                                    )
                            ) ?? Date(),
                        note: "京都出发日期"
                    ),
                    MemorySubject.TimeAnchor(
                        title: "抵达",
                        date:
                            Calendar.current.date(
                                from:
                                    DateComponents(
                                        year: 2025,
                                        month: 3,
                                        day: 30
                                    )
                            ) ?? Date(),
                        note: "京都抵达日期"
                    ),
                    MemorySubject.TimeAnchor(
                        title: "回程",
                        date:
                            Calendar.current.date(
                                from:
                                    DateComponents(
                                        year: 2025,
                                        month: 4,
                                        day: 5
                                    )
                            ) ?? Date(),
                        note: "京都回程日期"
                    )
                ],
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "初次到访",
                        iconStrategy: .fixed,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            MemoryExpression(
                                title: "旅行记忆",
                                blocks: [
                                    MemoryBlock(
                                        type: .memory,
                                        title: "生命时间",
                                        value: "生命时间"
                                    ),
                                    .text(" · "),
                                    MemoryBlock(
                                        type: .photo,
                                        title: "拍摄日期",
                                        value: "拍摄日期"
                                    )
                                ]
                            )
                    ),
                decorations: [
                    DecorationAsset(
                        kind: .icon,
                        title: "位置",
                        systemSymbolName: "location.fill"
                    )
                ]
            )

        let decorations = [
            icon,
            badge,
            DecorationAsset(
                kind: .icon,
                strategy: .fixed,
                title: "标记",
                systemSymbolName: "flag.fill"
            ),
            DecorationAsset(
                kind: .badge,
                strategy: .autoMatch,
                title: "Apple",
                systemSymbolName: "apple.logo"
            ),
            DecorationAsset(
                kind: .future,
                strategy: .none,
                title: "未来装饰",
                systemSymbolName: "sparkles"
            )
        ]

        let preset1 =
            MemoryPreset(
                title: "成长记录",
                summary: "记录、时间线、拍摄参数和记忆表达使用第一套配置。",
                regionTemplateIDs: [
                    .slotA: "recorder.configuration1",
                    .slotB: "timeline.configuration1",
                    .slotC: "context.configuration1",
                    .slotD: "memory.configuration1"
                ]
            )

        let preset2 =
            MemoryPreset(
                title: "第一次旅行",
                summary: "更强调日期、地点和旅行记忆表达。",
                regionTemplateIDs: [
                    .slotA: "recorder.configuration2",
                    .slotB: "timeline.configuration2",
                    .slotC: "context.configuration2",
                    .slotD: "memory.configuration2"
                ]
            )

        let preset3 =
            MemoryPreset(
                title: "自定义预设",
                summary: "预留给用户组合自己的区域配置。",
                regionTemplateIDs: [
                    .slotA: "recorder.configuration3",
                    .slotB: "timeline.configuration3",
                    .slotC: "context.configuration3",
                    .slotD: "memory.configuration3"
                ]
            )

        return ConfigurationCenterState(
            subjects: [
                subject,
                travelSubject
            ],
            selectedSubjectID: subject.id,
            memoryPresets: [
                preset1,
                preset2,
                preset3
            ],
            selectedMemoryPresetID: preset1.id,
            cardSelection: .defaultSelection,
            selectedBlockID: nil,
            tokenLibrary: TokenLibrary(),
            availableDecorations: decorations,
            regionPreviewTexts: [
                .slotA: ConfigurationSession.defaultPreviewText(
                    for: .slotA,
                    subject: subject
                ),
                .slotB: ConfigurationSession.defaultPreviewText(
                    for: .slotB,
                    subject: subject
                ),
                .slotC: ConfigurationSession.defaultPreviewText(
                    for: .slotC,
                    subject: subject
                ),
                .slotD: ConfigurationSession.defaultPreviewText(
                    for: .slotD,
                    subject: subject
                )
            ]
        )
    }
}
#endif
