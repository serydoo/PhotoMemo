import SwiftUI

fileprivate enum MainOperationGuideCategory:
    String,
    CaseIterable,
    Identifiable {

    case basics

    case workspace

    case editing

    case smartModules

    case output

    var id: String {
        rawValue
    }

    fileprivate var title: String {

        switch self {

        case .basics:
            return "开始使用"

        case .workspace:
            return "配置工作区"

        case .editing:
            return "模板与内容"

        case .smartModules:
            return "智能与时间点"

        case .output:
            return "输出与相册"
        }
    }

    fileprivate var summary: String {

        switch self {

        case .basics:
            return "先理解 PhotoMemo 的主界面分工和校准逻辑。"

        case .workspace:
            return "管理三套本地配置，切换、重命名和保存当前方案。"

        case .editing:
            return "处理四个自定义区域，以及标题、记忆文案和批量说明。"

        case .smartModules:
            return "理解时间点、智能模块和时间结果的组合方式。"

        case .output:
            return "确认保存去向，并把处理后的新图写入目标相册。"
        }
    }

    fileprivate var iconName: String {

        switch self {

        case .basics:
            return "sparkles.rectangle.stack"

        case .workspace:
            return "square.grid.2x2"

        case .editing:
            return "rectangle.and.pencil.and.ellipsis"

        case .smartModules:
            return "calendar.badge.clock"

        case .output:
            return "externaldrive.badge.checkmark"
        }
    }

    fileprivate var topics: [MainOperationGuideTopic] {

        MainOperationGuideTopic.allCases.filter {
            $0.category == self
        }
    }
}

fileprivate struct MainOperationGuideSection:
    Identifiable,
    Hashable {

    let title: String

    let items: [String]

    var id: String {
        title
    }
}

enum MainOperationGuideTopic:
    String,
    CaseIterable,
    Identifiable,
    Hashable {

    case overview

    case configurations

    case composer

    case supplementalContent

    case smartModules

    case output

    var id: String {
        rawValue
    }

    fileprivate var category: MainOperationGuideCategory {

        switch self {

        case .overview:
            return .basics

        case .configurations:
            return .workspace

        case .composer,
             .supplementalContent:
            return .editing

        case .smartModules:
            return .smartModules

        case .output:
            return .output
        }
    }

    fileprivate var title: String {

        switch self {

        case .overview:
            return "主界面总览"

        case .configurations:
            return "三套配置槽位"

        case .composer:
            return "四个自定义区域"

        case .supplementalContent:
            return "补充信息与批量说明"

        case .smartModules:
            return "时间点与智能模块"

        case .output:
            return "输出与相册保存"
        }
    }

    fileprivate var summary: String {

        switch self {

        case .overview:
            return "理解左侧编辑、右侧预览和底层真实渲染链路之间的关系。"

        case .configurations:
            return "切换、保存和命名三套本地方案，让整套模板参数一起刷新。"

        case .composer:
            return "确保插入内容始终进入明确选中的区域，不走隐式兜底。"

        case .supplementalContent:
            return "管理标题、记忆文案，以及图片说明是否使用单独批量内容。"

        case .smartModules:
            return "把 EXIF 拍摄时间和锚点时间转换成可组合的时间结果。"

        case .output:
            return "确认保存去向，并理解 PhotoMemo 的本地写回策略。"
        }
    }

    fileprivate var iconName: String {

        switch self {

        case .overview:
            return "rectangle.3.group"

        case .configurations:
            return "square.grid.2x2"

        case .composer:
            return "square.and.pencil"

        case .supplementalContent:
            return "text.badge.plus"

        case .smartModules:
            return "calendar.badge.clock"

        case .output:
            return "square.and.arrow.down"
        }
    }

    fileprivate var introduction: String {

        switch self {

        case .overview:
            return "PhotoMemo 的主界面不是批量工作台，而是单张照片的模板校准中心。左侧负责模板、时间点、自定义区域和输出规则，右侧负责实时预览、配置切换和帮助入口。所有调整都应继续绑定真实的导入、渲染、导出链路。"

        case .configurations:
            return "三套配置槽位一次只生效一套。切换配置时，模板、Logo 标识、时间点、补充信息和相册去向会一起刷新；保存时会把当前编辑状态整体写回当前高亮的槽位。"

        case .composer:
            return "四个自定义区域是 PhotoMemo 最核心的组合层。无论输入自定义文字还是插入 EXIF、智能模块，都必须先明确选中区域，再按光标位置组合内容。"

        case .supplementalContent:
            return "补充信息区负责额外语义，而不是替代模板。标题和记忆文案帮助卡片更完整；批量说明勾选后，会优先把单独录入的内容写入图片说明，不勾选时会回退到右下区域最终生成的完整内容。"

        case .smartModules:
            return "智能模块只输出时间结果本身，例如年岁、纪念时长、已过天数、倒计时和里程碑，不会自动帮你写整句。最终句子由你把模块和文字自由组合。"

        case .output:
            return "PhotoMemo 会生成一张新图，并按当前本地链路把它写回系统图库。输出区的重点是选对目标相册，并让处理后的图片继续保留尽可能完整的原图元数据。"
        }
    }

    fileprivate var sections: [MainOperationGuideSection] {

        switch self {

        case .overview:
            return [
                MainOperationGuideSection(
                    title: "界面分工",
                    items: [
                        "左侧负责模板、时间点、Logo 标识、补充信息、自定义区域和输出规则的编辑。",
                        "右侧负责实时预览、三套配置切换和帮助中心入口，用来对照校准结果。",
                        "主界面只保留一张校准照片，避免把界面做成批量工作台。"
                    ]
                ),
                MainOperationGuideSection(
                    title: "建议顺序",
                    items: [
                        "先选模板，再设置时间点，然后导入一张真实照片做校准。",
                        "确认右下智能结果和 EXIF 信息正常后，再补标题、说明和输出相册。",
                        "最后把满意的一套方案保存到某个配置槽位，给后续外部导入和后台处理复用。"
                    ]
                )
            ]

        case .configurations:
            return [
                MainOperationGuideSection(
                    title: "配置切换规则",
                    items: [
                        "顶部三张配置卡片对应三套本地方案，始终只有一套高亮生效。",
                        "切换后左侧字段和右侧预览会同步刷新，方便你直接对照差异。",
                        "未单独保存过的槽位会先使用各自默认骨架：模板 1、模板 2、模板 3。"
                    ]
                ),
                MainOperationGuideSection(
                    title: "命名与保存",
                    items: [
                        "“重命名当前配置”只会修改槽位名称，帮助你用“宝宝成长”“旅行纪念”等方式管理方案，不会改模板名称。",
                        "“保存到当前配置”会把当前模板、时间点、Logo 标识、补充信息和相册去向整体写回当前槽位。",
                        "“恢复当前默认”只会清空该槽位保存的配置快照，槽位名称仍可保留。"
                    ]
                )
            ]

        case .composer:
            return [
                MainOperationGuideSection(
                    title: "插入原则",
                    items: [
                        "先选中左上、右上、左下或右下某个区域，再插入 EXIF、智能模块或自定义文字。",
                        "系统不会再偷偷把内容插到右下区域，所有插入都以当前明确选中的区域为准。",
                        "选中区域后可以直接输入文字；点击上方模块按钮时，模块会按当前光标位置插入。"
                    ]
                ),
                MainOperationGuideSection(
                    title: "编辑方式",
                    items: [
                        "每个区域都可以独立编辑，适合把标题、拍摄参数、时间表达和记忆句子自由混排。",
                        "模块插入后会显示成人类可读的标签文本，方便你继续在前后补自定义短语。",
                        "如果想删除某个模块或一段文字，直接把光标放到附近，用正常文本编辑方式处理即可。",
                        "切换模板或恢复模板默认字段后，编辑态会同步刷新，避免旧状态残留。"
                    ]
                )
            ]

        case .supplementalContent:
            return [
                MainOperationGuideSection(
                    title: "内容定位",
                    items: [
                        "标题适合写卡片主题，例如“第一次海边日落”。",
                        "记忆文案适合补充一段简短上下文，例如“出门前还一直担心会下雨”。",
                        "这些内容属于补充信息，不会替代右下智能模块的真实时间结果。"
                    ]
                ),
                MainOperationGuideSection(
                    title: "批量说明勾选",
                    items: [
                        "勾选“使用单独批量说明内容”后，图片说明会优先写入你单独输入的内容。",
                        "如果勾选后内容留空，系统会自动回退到右下区域最终生成的完整结果。",
                        "如果不勾选，系统会直接把右下区域当前组合出来的完整内容作为图片说明写入。"
                    ]
                )
            ]

        case .smartModules:
            return [
                MainOperationGuideSection(
                    title: "时间点作用",
                    items: [
                        "时间点决定系统是在算年岁、纪念时长、已过多久，还是未来倒计时。",
                        "照片导入后会优先用 EXIF 拍摄时间参与计算，因此导入真实照片比空状态更接近最终效果。",
                        "当用户未满 1 岁时，年龄结果不会再显示“0岁8个月”这类不自然写法。"
                    ]
                ),
                MainOperationGuideSection(
                    title: "常用智能结果",
                    items: [
                        "年岁适合成长记录中的年龄表达。",
                        "纪念时长、已过天数适合纪念日和已经过去多久的场景。",
                        "倒计时、第几天、里程碑适合目标倒计时、阶段记录和关键节点表达。"
                    ]
                )
            ]

        case .output:
            return [
                MainOperationGuideSection(
                    title: "相册保存方式",
                    items: [
                        "输出区只保留一个目标相册选择入口，处理完成后会把新图直接写回你选中的系统相册。",
                        "如果不手动指定现有相册，系统会自动创建或复用 PhotoMemo 相册。",
                        "PhotoMemo 的目标是继续复刻原图 EXIF、拍摄时间与可保留元数据，同时生成一张新的成品图。"
                    ]
                ),
                MainOperationGuideSection(
                    title: "使用建议",
                    items: [
                        "保存前先确认当前模板、时间点和右侧预览已经是最终结果。",
                        "PhotoMemo 会生成一张新图，而不是修改原图，所以原照片仍会留在系统图库里。",
                        "如果之后你还想换输出去向，直接切换当前配置槽位或重新选择目标相册即可。"
                    ]
                )
            ]
        }
    }
}

struct MainDismissibleGuideCard: View {

    @AppStorage
    private var isDismissed: Bool

    let title: String

    let message: String

    init(
        storageKey: String,
        title: String,
        message: String
    ) {
        self.title = title
        self.message = message
        _isDismissed = AppStorage(
            wrappedValue: false,
            storageKey
        )
    }

    var body: some View {

        if !isDismissed {
            HStack(
                alignment: .top,
                spacing: 12
            ) {

                Image(
                    systemName: "doc.text.magnifyingglass"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(
                    MinimalPalette.accent
                )
                .padding(.top, 2)

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    Text(title)
                        .font(.caption.weight(.semibold))

                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                Spacer(minLength: 0)

                Button {
                    isDismissed = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(Color.white.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(MinimalPalette.border)
            )
        }
    }
}

struct MainWorkspaceConfigurationPanelView: View {

    let slots: [WorkspaceConfigurationSlot]

    let activeSlotID: WorkspaceConfigurationSlotID

    let activeSlotSummary: String

    let activeSlotDisplayTitle: String

    let onSelectSlot:
        (WorkspaceConfigurationSlotID) -> Void

    let onRenameActiveSlot: () -> Void

    let onSaveActiveSlot: () -> Void

    let onRestoreActiveSlotDefault: () -> Void

    let onOpenGuideTopic:
        (MainOperationGuideTopic) -> Void

    var body: some View {

        MinimalInsetCard {
            HStack(
                alignment: .center,
                spacing: 12
            ) {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("配置工作区")
                        .font(.headline)

                    Text("右侧负责切换当前生效的整套本地配置，并统一管理保存、命名和帮助入口。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                Spacer(minLength: 0)

                Menu {

                    ForEach(
                        MainOperationGuideCategory.allCases
                    ) { category in

                        Menu {
                            ForEach(category.topics) { topic in

                                Button(topic.title) {
                                    onOpenGuideTopic(topic)
                                }
                            }

                        } label: {
                            Label(
                                category.title,
                                systemImage:
                                    category.iconName
                            )
                        }
                    }
                } label: {
                    Label(
                        "帮助中心",
                        systemImage: "books.vertical"
                    )
                }
                .menuStyle(.borderlessButton)
                .controlSize(.small)
            }

            HStack(spacing: 10) {

                ForEach(slots) { slot in

                    MainWorkspaceConfigurationSlotButton(
                        slot: slot,
                        isActive:
                            slot.id == activeSlotID,
                        onSelect: {
                            onSelectSlot(slot.id)
                        }
                    )
                }
            }

            MinimalInsetCard {
                LabeledContent("当前配置") {
                    Text(activeSlotDisplayTitle)
                        .font(.subheadline.weight(.semibold))
                }

                Divider()

                Text(activeSlotSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            HStack(spacing: 10) {
                Button("重命名当前配置") {
                    onRenameActiveSlot()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("保存到当前配置") {
                    onSaveActiveSlot()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("恢复当前默认") {
                    onRestoreActiveSlotDefault()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
}

private struct MainWorkspaceConfigurationSlotButton: View {

    let slot: WorkspaceConfigurationSlot

    let isActive: Bool

    let onSelect: () -> Void

    var body: some View {

        Button(action: onSelect) {
            VStack(
                alignment: .leading,
                spacing: 6
            ) {

                HStack {
                    Text(slot.displayTitle)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Text(slot.statusText)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(
                            isActive
                            ? MinimalPalette.accent
                            : .secondary
                        )
                }

                Text(slot.resolvedDisplayName)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)

                Text(
                    slotDescription
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding(12)
            .background(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(
                    isActive
                    ? MinimalPalette.accent
                        .opacity(0.12)
                    : Color.white.opacity(0.72)
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(
                    isActive
                    ? MinimalPalette.accent
                        .opacity(0.4)
                    : MinimalPalette.border
                )
            )
        }
        .buttonStyle(.plain)
    }

    private var slotDescription: String {

        if isActive {
            return slot.isCustomized
                ? "当前生效配置"
                : "当前使用\(slot.defaultPreset.displayName)默认骨架"
        }

        return slot.isCustomized
            ? "切换到这套已保存配置"
            : "未保存时使用\(slot.defaultPreset.displayName)默认骨架"
    }
}

struct MainWorkspaceConfigurationRenameSheetView:
    View {

    let slotReferenceTitle: String

    let currentDisplayTitle: String

    @Binding
    var titleDraft: String

    let onCancel: () -> Void

    let onSave: () -> Void

    var body: some View {

        NavigationStack {
            VStack(
                alignment: .leading,
                spacing: 16
            ) {

                Text("为当前配置槽位设置一个更好记的名称，方便区分成长记录、旅行纪念或节日模板等不同方案。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                MinimalInsetCard {
                    LabeledContent("槽位编号") {
                        Text(slotReferenceTitle)
                            .font(.caption.weight(.medium))
                    }

                    Divider()

                    LabeledContent("当前显示") {
                        Text(currentDisplayTitle)
                            .font(.caption.weight(.medium))
                    }
                }

                TextField(
                    "例如：宝宝成长 / 旅行纪念 / 高考倒计时",
                    text: $titleDraft
                )
                .textFieldStyle(.roundedBorder)

                Text("留空后保存，会恢复成默认名称 \(slotReferenceTitle)。这里只改配置槽位名称，不会修改模板名称。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                Spacer(minLength: 0)
            }
            .padding(24)
            .navigationTitle("重命名配置")
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("取消") {
                        onCancel()
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {

                    Button("保存名称") {
                        onSave()
                    }
                }
            }
        }
        .frame(
            minWidth: 420,
            minHeight: 280
        )
    }
}

struct MainOperationGuideSheetView: View {

    @State
    private var selectedTopic:
        MainOperationGuideTopic

    let onDismiss: () -> Void

    init(
        selectedTopic: MainOperationGuideTopic,
        onDismiss: @escaping () -> Void
    ) {
        _selectedTopic = State(
            initialValue: selectedTopic
        )
        self.onDismiss = onDismiss
    }

    var body: some View {

        NavigationSplitView {
            List(selection: $selectedTopic) {
                ForEach(
                    MainOperationGuideCategory.allCases
                ) { category in

                    Section {
                        ForEach(category.topics) { topic in

                            MainOperationGuideSidebarRow(
                                topic: topic
                            )
                            .tag(topic)
                        }

                    } header: {
                        Label(
                            category.title,
                            systemImage:
                                category.iconName
                        )
                    } footer: {
                        Text(category.summary)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("帮助中心")
            .navigationSplitViewColumnWidth(
                min: 250,
                ideal: 290
            )

        } detail: {
            MainOperationGuideDetailView(
                topic: selectedTopic
            )
        }
        .toolbar {
            ToolbarItem(
                placement: .cancellationAction
            ) {
                Button("关闭") {
                    onDismiss()
                }
            }
        }
        .frame(
            minWidth: 920,
            minHeight: 620
        )
    }
}

private struct MainOperationGuideSidebarRow:
    View {

    let topic: MainOperationGuideTopic

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 10
        ) {

            Image(systemName: topic.iconName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(
                    MinimalPalette.accent
                )
                .frame(width: 18)
                .padding(.top, 2)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(topic.title)
                    .font(.subheadline.weight(.semibold))

                Text(topic.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
        }
        .padding(.vertical, 4)
    }
}

private struct MainOperationGuideDetailView:
    View {

    let topic: MainOperationGuideTopic

    var body: some View {

        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                headerCard

                ForEach(topic.sections) { section in

                    MinimalInsetCard {
                        Text(section.title)
                            .font(.headline)

                        VStack(
                            alignment: .leading,
                            spacing: 10
                        ) {

                            ForEach(
                                section.items,
                                id: \.self
                            ) { item in

                                HStack(
                                    alignment: .top,
                                    spacing: 10
                                ) {

                                    Image(
                                        systemName:
                                            "checkmark.circle.fill"
                                    )
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(
                                        MinimalPalette.accent
                                    )
                                    .padding(.top, 3)

                                    Text(item)
                                        .font(.subheadline)
                                        .fixedSize(
                                            horizontal: false,
                                            vertical: true
                                        )
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(
            MinimalPalette.background
                .ignoresSafeArea()
        )
    }

    private var headerCard: some View {

        MinimalInsetCard {
            HStack(
                alignment: .top,
                spacing: 14
            ) {

                Image(systemName: topic.iconName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(
                        MinimalPalette.accent
                    )
                    .frame(width: 28)
                    .padding(.top, 2)

                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {

                    Text(topic.category.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(topic.title)
                        .font(.title3.weight(.semibold))

                    Text(topic.summary)
                        .font(.subheadline.weight(.medium))

                    Text(topic.introduction)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }
            }
        }
    }
}
