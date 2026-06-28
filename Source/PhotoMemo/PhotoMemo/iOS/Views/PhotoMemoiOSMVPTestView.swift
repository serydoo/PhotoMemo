#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct PhotoMemoiOSMVPTestView: View {

    @StateObject
    private var session = ConfigurationSession()

    @State
    private var regionDrafts: [CardRegion: MVPEditorDraft] = [:]

    @State
    private var activeModuleRegion: CardRegion?

    @State
    private var selectedModule: IOSInsertableModule?

    @State
    private var logoMode: MVPLogoMode = .appleMini

    @State
    private var birthdayDate =
        Calendar.current.date(
            from: DateComponents(
                year: 2024,
                month: 4,
                day: 18
            )
        ) ?? Date()

    @State
    private var outputTarget: MVPIOSOutputTarget = .applePhotos

    @State
    private var targetAlbumName = "途途相册"

    @State
    private var profileOffsetY: CGFloat = 0

    @State
    private var previewOffsetY: CGFloat = 0

    @State
    private var didBootstrap = false

    private let captureTimeResolver = CaptureTimeResolver()

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let overlayWidth = min(proxy.size.width * 0.72, 540)

                ZStack(alignment: .top) {
                    ScrollView {
                        VStack(spacing: 16) {
                            profileSection
                                .background(
                                    offsetReader(
                                        for: .profile
                                    )
                                )

                            previewSection
                                .background(
                                    offsetReader(
                                        for: .preview
                                    )
                                )
                                .opacity(
                                    max(
                                        1 - previewPinProgress,
                                        0
                                    )
                                )

                            editorCluster
                                .opacity(
                                    max(editorRevealProgress, 0.08)
                                )
                                .offset(
                                    y: (1 - editorRevealProgress) * 12
                                )

                            logoSection
                            birthdaySection
                            outputSection
                            memoryWriteSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 28)
                    }

                    if previewPinProgress > 0.01 {
                        previewSection
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            .opacity(previewPinProgress)
                            .allowsHitTesting(false)
                    }

                    if let region = activeModuleRegion {
                        moduleLibraryOverlay(
                            region: region,
                            width: overlayWidth
                        )
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .top
                )
                .background(ConfigurationUI.appBackground.ignoresSafeArea())
                .coordinateSpace(name: "mvp-scroll")
            }
            .navigationTitle("PhotoMemo MVP 测试")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.light)
        .onAppear {
            bootstrapIfNeeded()
        }
        .onChange(of: session.state.selectedMemoryPresetID) { _, _ in
            bootstrapDrafts()
        }
        .onChange(of: birthdayDate) { _, _ in
            refreshDynamicPreview()
        }
    }

    private var profileSection: some View {
        MVPCardSurface(title: "Profile") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    presetPicker

                    Spacer(minLength: 0)

                    Button("应用") {
                        session.applySelectedMemoryPreset()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Text("默认")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Button("重置") {
                        session.resetSelectedMemoryPreset()
                        bootstrapDrafts()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("当前记忆对象摘要")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(session.currentConfigurationLabel)
                        .font(.headline.weight(.semibold))

                    Text(session.state.selectedSubject?.definition ?? "可后续接入 ConfigurationSession mock 数据。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var previewSection: some View {
        MVPPreviewCard(
            logoMode: logoMode,
            regionText:
                previewText(
                    for: CardRegion.region(for: .leftPrimary)
                ),
            timeText:
                previewText(
                    for: CardRegion.region(for: .leftSecondary)
                ),
            contextText:
                previewText(
                    for: CardRegion.region(for: .rightPrimary)
                ),
            memoryText:
                previewText(
                    for: CardRegion.region(for: .rightSecondary)
                )
        )
    }

    private var editorCluster: some View {
        VStack(spacing: 12) {
            ForEach(CardRegion.memoryCardRegions, id: \.self) { region in
                MVPRegionEditorCard(
                    region: region,
                    draft: draft(for: region),
                    onFocus: {
                        activeModuleRegion = region
                        selectedModule = nil
                    },
                    onUpdateBaseText: { text in
                        updateDraft(for: region) { draft in
                            draft.baseText = text
                        }
                    },
                    onUpdateContinuationText: { text in
                        updateDraft(for: region) { draft in
                            draft.continuationText = text
                        }
                    },
                    onRemoveModule: { module in
                        updateDraft(for: region) { draft in
                            draft.modules.removeAll { $0.id == module.id }
                        }
                        refreshPreview(for: region)
                    },
                    onShowModules: {
                        activeModuleRegion = region
                    }
                )
            }
        }
    }

    private var logoSection: some View {
        MVPCardSurface(title: "显示标志") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Logo 标识", selection: $logoMode) {
                    ForEach(MVPLogoMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                HStack(alignment: .center, spacing: 12) {
                    logoPreview

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Logo 标识")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(logoMode.title)
                            .font(.subheadline.weight(.semibold))
                    }

                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var birthdaySection: some View {
        MVPCardSurface(title: "途途生日") {
            VStack(alignment: .leading, spacing: 12) {
                DatePicker(
                    "途途生日",
                    selection: $birthdayDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("智能模块")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(smartTimeResult)
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
    }

    private var outputSection: some View {
        MVPCardSurface(title: "输出区域") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("输出到", selection: $outputTarget) {
                    ForEach(MVPIOSOutputTarget.allCases) { target in
                        Text(target.title).tag(target)
                    }
                }
                .pickerStyle(.segmented)

                if outputTarget == .specificAlbum {
                    TextField("指定相册名称", text: $targetAlbumName)
                        .textFieldStyle(.roundedBorder)
                }

                Text(outputTarget.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var memoryWriteSection: some View {
        MVPCardSurface(title: "写入记忆") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(
                    "是否写入记忆说明",
                    isOn: $session.usesCustomMemoryWriteText
                )

                if session.usesCustomMemoryWriteText {
                    TextField(
                        "自定义写入内容",
                        text: $session.customMemoryWriteText,
                        axis: .vertical
                    )
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("预览")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(session.resolvedMemoryWriteText)
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
    }

    private var presetPicker: some View {
        Menu {
            Picker("当前 Preset", selection: selectedPresetBinding) {
                ForEach(session.state.memoryPresets) { preset in
                    Text(preset.title).tag(preset.id)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.caption.weight(.semibold))
                Text(session.currentMemoryPresetTitle)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentColor.opacity(0.18))
            )
        }
    }

    private var logoPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(width: 74, height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                        .foregroundStyle(Color.black.opacity(0.10))
                )

            switch logoMode {
            case .appleMini:
                Image(systemName: "apple.logo")
                    .font(.title2.weight(.semibold))
            case .customPlaceholder:
                VStack(spacing: 4) {
                    Image(systemName: "photo.badge.plus")
                        .font(.title3.weight(.semibold))
                    Text("占位")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private func moduleLibraryOverlay(
        region: CardRegion,
        width: CGFloat
    ) -> some View {
        ZStack {
            Color.black.opacity(0.16)
                .ignoresSafeArea()
                .onTapGesture {
                    activeModuleRegion = nil
                    selectedModule = nil
                }

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(region.semanticTitle)
                            .font(.headline.weight(.semibold))
                        Text("点选模块后点击插入到编辑区")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    Button("关闭") {
                        activeModuleRegion = nil
                        selectedModule = nil
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ],
                    spacing: 8
                ) {
                    ForEach(modules(for: region)) { module in
                        Button {
                            selectedModule = module
                        } label: {
                            moduleCard(module, isSelected: selectedModule == module)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 8) {
                    Text(selectedModule?.title ?? "先选择一个模块")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 0)

                    Button("插入") {
                        guard let selectedModule, activeModuleRegion == region else {
                            return
                        }
                        insert(selectedModule, into: region)
                        activeModuleRegion = nil
                        self.selectedModule = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedModule == nil)
                }
            }
            .padding(14)
            .frame(width: width, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(ConfigurationUI.faintHairline)
            )
            .shadow(color: ConfigurationUI.cardShadow, radius: 22, y: 10)
            .padding(.top, 100)
        }
    }

    private func moduleCard(
        _ module: IOSInsertableModule,
        isSelected: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: module.systemImage)
                    .font(.caption.weight(.semibold))
                Text(module.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }

            Text(moduleValue(module))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Color.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    isSelected
                    ? Color.accentColor.opacity(0.11)
                    : Color.black.opacity(0.03)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isSelected
                    ? Color.accentColor.opacity(0.30)
                    : ConfigurationUI.faintHairline
                )
        )
    }

    private func draft(for region: CardRegion) -> MVPEditorDraft {
        regionDrafts[region]
        ?? makeDefaultDraft(for: region)
    }

    private func updateDraft(
        for region: CardRegion,
        transform: (inout MVPEditorDraft) -> Void
    ) {
        var draft = draft(for: region)
        transform(&draft)
        regionDrafts[region] = draft
        refreshPreview(for: region)
    }

    private func refreshPreview(for region: CardRegion) {
        let draft = draft(for: region)
        let composed = composedText(for: draft)
        session.updateRegionPreview(region: region, text: composed)
    }

    private func refreshDynamicPreview() {
        for region in CardRegion.memoryCardRegions {
            refreshPreview(for: region)
        }
    }

    private func previewText(
        for region: CardRegion
    ) -> String {
        session.previewText(for: region)
    }

    private func composedText(for draft: MVPEditorDraft) -> String {
        let parts = [
            draft.baseText.trimmingCharacters(in: .whitespacesAndNewlines),
            draft.modules
                .map(\.value)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: " "),
            draft.continuationText.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        .filter { !$0.isEmpty }

        return parts.joined(separator: " ")
    }

    private func makeDefaultDraft(
        for region: CardRegion
    ) -> MVPEditorDraft {
        let subject = session.state.selectedSubject
        let templateID = session.activeTemplateID(for: region)

        if region == .slotD {
            let recorderName: String

            if let subject,
               !subject.identity.shortName.isEmpty {
                recorderName = subject.identity.shortName
            } else {
                recorderName =
                    subject?.identity.displayName
                    ?? "Tutu"
            }

            return MVPEditorDraft(
                baseText: "\(recorderName) 当天",
                continuationText: "",
                modules: [
                    IOSInsertedModule(
                        title: IOSInsertableModule.smartTime.title,
                        value: smartTimeResult,
                        systemImage: IOSInsertableModule.smartTime.systemImage
                    )
                ]
            )
        }

        return MVPEditorDraft(
            baseText: ConfigurationSession.defaultPreviewText(
                for: region,
                templateID: templateID,
                subject: subject
            ),
            continuationText: "",
            modules: []
        )
    }

    private func insert(
        _ module: IOSInsertableModule,
        into region: CardRegion
    ) {
        updateDraft(for: region) { draft in
            draft.modules.append(
                IOSInsertedModule(
                    title: module.title,
                    value: moduleValue(module),
                    systemImage: module.systemImage
                )
            )
        }
    }

    private func modules(for region: CardRegion) -> [IOSInsertableModule] {
        switch region {
        case .slotA:
            return [
                .subjectNickname,
                .captureDate,
                .captureTime,
                .cameraModel,
                .smartTime,
                .custom
            ]
        case .slotB:
            return [
                .captureDate,
                .captureTime,
                .captureSummary,
                .smartTime,
                .custom
            ]
        case .slotC:
            return [
                .focalLength,
                .aperture,
                .iso,
                .shutterSpeed,
                .captureSummary,
                .cameraModel,
                .custom
            ]
        case .slotD:
            return [
                .subjectNickname,
                .smartTime,
                .captureDate,
                .captureTime,
                .location,
                .custom
            ]
        default:
            return []
        }
    }

    private func moduleValue(
        _ module: IOSInsertableModule
    ) -> String {
        switch module {
        case .subjectNickname:
            return session.state.selectedSubject?.identity.shortName
            ?? session.state.selectedSubject?.identity.displayName
            ?? "Tutu"
        case .smartTime:
            return smartTimeResult
        case .captureDate:
            return captureDateFormatter.string(from: mockCaptureDate)
        case .captureTime:
            return captureTimeFormatter.string(from: mockCaptureDate)
        case .cameraMaker:
            return "Apple"
        case .cameraModel:
            return "iPhone 17 Pro Max"
        case .lensModel:
            return ""
        case .focalLength:
            return "20mm"
        case .aperture:
            return "f/1.9"
        case .shutterSpeed:
            return "1/117s"
        case .iso:
            return "ISO80"
        case .exposureBias:
            return "0 EV"
        case .meteringMode:
            return "Pattern"
        case .flash:
            return "未开启"
        case .whiteBalance:
            return "自动"
        case .captureSummary:
            return "20mm f/1.9 1/117s ISO80"
        case .location:
            return "河南 · 商丘"
        case .altitude:
            return "42m"
        case .imageSize:
            return "4032 × 3024"
        case .orientation:
            return "横向"
        case .fileFormat:
            return "HEIC"
        case .custom:
            return "自定义内容"
        }
    }

    private var smartTimeResult: String {
        captureTimeResolver.resolveText(
            captureDate: mockCaptureDate,
            referenceDate: birthdayDate,
            calendar: smartTimeCalendar
        )
    }

    private var mockCaptureDate: Date {
        Calendar.current.date(
            from: DateComponents(
                year: 2026,
                month: 5,
                day: 24,
                hour: 14,
                minute: 33
            )
        ) ?? Date()
    }

    private var captureDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }

    private var captureTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }

    private var smartTimeCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600) ?? .current
        return calendar
    }

    private var editorRevealProgress: CGFloat {
        let threshold: CGFloat = 30
        let distance: CGFloat = 120
        let traveled = max(-(profileOffsetY) - threshold, 0)
        return min(traveled / distance, 1)
    }

    private var previewPinProgress: CGFloat {
        let threshold: CGFloat = 6
        let distance: CGFloat = 56
        let traveled = max(-(previewOffsetY) - threshold, 0)
        return min(traveled / distance, 1)
    }

    private func offsetReader(
        for kind: MVPScrollOffsetKind
    ) -> some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: MVPScrollOffsetPreferenceKey.self,
                    value: [
                        kind: proxy.frame(
                            in: .named("mvp-scroll")
                        ).minY
                    ]
                )
        }
        .onPreferenceChange(MVPScrollOffsetPreferenceKey.self) { values in
            if let profile = values[.profile] {
                profileOffsetY = profile
            }
            if let preview = values[.preview] {
                previewOffsetY = preview
            }
        }
    }

    private func bootstrapIfNeeded() {
        guard !didBootstrap else {
            return
        }

        didBootstrap = true
        bootstrapDrafts()
    }

    private func bootstrapDrafts() {
        var drafts: [CardRegion: MVPEditorDraft] = [:]

        for region in CardRegion.memoryCardRegions {
            drafts[region] = makeDefaultDraft(for: region)
        }

        regionDrafts = drafts
        refreshDynamicPreview()
    }

    private var selectedPresetBinding: Binding<MemoryPreset.ID> {
        Binding(
            get: {
                session.state.selectedMemoryPreset?.id
                ?? session.state.memoryPresets.first?.id
                ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
            },
            set: { newValue in
                guard let preset = session.state.memoryPresets.first(where: {
                    $0.id == newValue
                }) else {
                    return
                }
                session.selectMemoryPreset(preset)
                bootstrapDrafts()
            }
        )
    }
}

private struct MVPEditorDraft: Hashable {
    var baseText: String
    var continuationText: String
    var modules: [IOSInsertedModule]
}

private struct MVPCardSurface<Content: View>: View {

    let title: String
    @ViewBuilder var content: Content

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ConfigurationUI.faintHairline)
        )
        .shadow(color: ConfigurationUI.cardShadow, radius: 12, y: 6)
    }
}

private struct MVPPreviewCard: View {

    let logoMode: MVPLogoMode
    let regionText: String
    let timeText: String
    let contextText: String
    let memoryText: String

    var body: some View {
        MVPCardSurface(title: "Preview") {
            Color.clear
            .aspectRatio(compactPreviewAspectRatio, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    compactPreviewCard(size: proxy.size)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ConfigurationUI.faintHairline)
            )
        }
    }

    private var compactSpec: CompactInformationBarSpec {
        RendererConstants.CompactInformationBar.landscape
    }

    private var compactPreviewAspectRatio: CGFloat {
        1 / compactSpec.barHeightToWidth
    }

    private func compactPreviewCard(size: CGSize) -> some View {
        let barHeight =
            size.width
            * compactSpec.barHeightToWidth

        return compactInformationBar(
            width: size.width,
            height: barHeight
        )
        .frame(height: barHeight)
    }

    private func compactInformationBar(
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        let spec = compactSpec

        return ZStack(alignment: .topLeading) {
            RendererConstants.CompactInformationBar.background

            compactTextPair(
                primary: regionText,
                secondary: timeText,
                spec: spec,
                barHeight: height
            )
            .frame(
                width: width * spec.leftWidth,
                height: height * 0.62,
                alignment: .leading
            )
            .position(
                x:
                    width * spec.leftX
                    + width * spec.leftWidth / 2,
                y: height * spec.contentCenterY
            )

            compactLogo(
                spec: spec,
                barHeight: height
            )
            .position(
                x: width * spec.logoCenterX,
                y: height * spec.contentCenterY
            )

            Rectangle()
                .fill(RendererConstants.CompactInformationBar.divider)
                .frame(
                    width:
                        min(
                            max(
                                height
                                * spec.dividerWidthToBarHeight,
                                1
                            ),
                            4
                        ),
                    height: height * spec.dividerHeight
                )
                .position(
                    x: width * spec.dividerCenterX,
                    y:
                        height * spec.dividerTopY
                        + height * spec.dividerHeight / 2
                )

            compactTextPair(
                primary: formattedCaptureSummaryText,
                secondary: memoryText,
                spec: spec,
                barHeight: height
            )
            .frame(
                width: width * spec.rightWidth,
                height: height * 0.62,
                alignment: .leading
            )
            .position(
                x:
                    width * spec.rightX
                    + width * spec.rightWidth / 2,
                y: height * spec.contentCenterY
            )
        }
    }

    private func compactTextPair(
        primary: String,
        secondary: String,
        spec: CompactInformationBarSpec,
        barHeight: CGFloat
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: barHeight * spec.groupSpacingToBarHeight
        ) {
            compactTextLine(
                primary,
                fontSize:
                    barHeight
                    * spec.primaryFontToBarHeight,
                weight: .bold,
                tracking: spec.primaryTracking,
                color:
                    RendererConstants
                    .CompactInformationBar
                    .primaryText
            )

            compactTextLine(
                secondary,
                fontSize:
                    barHeight
                    * spec.secondaryFontToBarHeight,
                weight: .regular,
                tracking: spec.secondaryTracking,
                color:
                    RendererConstants
                    .CompactInformationBar
                    .secondaryText
            )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
    }

    private func compactTextLine(
        _ value: String,
        fontSize: CGFloat,
        weight: Font.Weight,
        tracking: CGFloat,
        color: Color
    ) -> some View {
        Text(value.isEmpty ? " " : value)
            .font(
                .system(
                    size: fontSize,
                    weight: weight
                )
            )
            .kerning(tracking)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func compactLogo(
        spec: CompactInformationBarSpec,
        barHeight: CGFloat
    ) -> some View {
        let logoSize =
            barHeight
            * spec.logoSizeToBarHeight

        return Group {
            switch logoMode {
            case .appleMini:
                Image(systemName: "apple.logo")
                    .font(.system(size: logoSize, weight: .semibold))
            case .customPlaceholder:
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: logoSize * 0.78, weight: .semibold))
            }
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(RendererConstants.CompactInformationBar.logoTint)
        .frame(width: logoSize * 1.25, height: logoSize * 1.25)
    }

    private var formattedCaptureSummaryText: String {
        let facts =
            contextText
            .split(separator: " ")
            .map(String.init)
            .prefix(RendererConstants.CaptureSummary.allowedFactCount)

        guard !facts.isEmpty else {
            return contextText
        }

        return facts.joined(separator: " ")
    }
}

private struct MVPRegionEditorCard: View {

    let region: CardRegion
    let draft: MVPEditorDraft
    let onFocus: () -> Void
    let onUpdateBaseText: (String) -> Void
    let onUpdateContinuationText: (String) -> Void
    let onRemoveModule: (IOSInsertedModule) -> Void
    let onShowModules: () -> Void

    var body: some View {
        MVPCardSurface(title: region.semanticTitle) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(region.displayTitle)
                        .font(.headline.weight(.semibold))
                    Spacer()
                    Button("模块窗口") {
                        onShowModules()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                TextField(
                    "第一段输入",
                    text: Binding(
                        get: { draft.baseText },
                        set: onUpdateBaseText
                    ),
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...3)
                .onTapGesture(perform: onFocus)

                if !draft.modules.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(draft.modules) { module in
                                HStack(spacing: 4) {
                                    Image(systemName: module.systemImage)
                                    Text(module.title)
                                    if !module.value.isEmpty {
                                        Text(module.value)
                                            .foregroundStyle(.secondary)
                                    }
                                    Button {
                                        onRemoveModule(module)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.secondary)
                                }
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.accentColor.opacity(0.09))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.accentColor.opacity(0.16))
                                )
                            }
                        }
                        .padding(.vertical, 1)
                    }
                }

                TextField(
                    "继续输入",
                    text: Binding(
                        get: { draft.continuationText },
                        set: onUpdateContinuationText
                    ),
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...2)
                .onTapGesture(perform: onFocus)
            }
        }
    }
}

private enum MVPLogoMode:
    String,
    CaseIterable,
    Identifiable {

    case appleMini
    case customPlaceholder

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .appleMini:
            return "Apple mini-logo"
        case .customPlaceholder:
            return "自选上传占位"
        }
    }
}

private enum MVPIOSOutputTarget:
    String,
    CaseIterable,
    Identifiable {

    case applePhotos
    case specificAlbum

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .applePhotos:
            return "Apple Photos"
        case .specificAlbum:
            return "指定相册"
        }
    }

    var note: String {
        switch self {
        case .applePhotos:
            return "仅 UI 状态，不调用真实写库。"
        case .specificAlbum:
            return "仅测试相册选择状态，不写入真实 Photo Library。"
        }
    }
}

private enum MVPScrollOffsetKind:
    Hashable {

    case profile
    case preview
}

private struct MVPScrollOffsetPreferenceKey:
    PreferenceKey {

    static var defaultValue: [MVPScrollOffsetKind: CGFloat] = [:]

    static func reduce(
        value: inout [MVPScrollOffsetKind: CGFloat],
        nextValue: () -> [MVPScrollOffsetKind: CGFloat]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

#Preview("iOS MVP 测试") {
    PhotoMemoiOSMVPTestView()
}
#endif
