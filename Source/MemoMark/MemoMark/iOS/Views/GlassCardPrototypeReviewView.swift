#if DEBUG && os(iOS) && !MEMOMARK_SHARE_EXTENSION
import ImageIO
import SwiftUI

/// Disposable, local-only review surface for GlassCard appearance candidates.
/// Its fixtures never enter a Template, Configuration, or output pipeline.
struct GlassCardPrototypeReviewView: View {

    @State private var scene: GlassCardPrototypeSceneKind = .brightCoast
    @State private var orientation: GlassCardPrototypeOrientation = .portrait
    @State private var textFixture: GlassCardPrototypeTextFixture = .referenceWidth
    @State private var surfaceCandidate: GlassCardPrototypeSurfaceCandidate = .systemMaterial
    @State private var edgeCandidate: GlassCardPrototypeEdgeCandidate = .restrainedKeyline
    @State private var inkCandidate: GlassCardPrototypeInkCandidate = .referenceWhite
    @State private var compositionCandidate: GlassCardPrototypeCompositionCandidate = .referenceArrangement
    @State private var typeScale: GlassCardPrototypeTypeScale = .referenceFit
    @State private var textFitCandidate: GlassCardPrototypeTextFitCandidate = .singleLine
    @State private var leftTopState: GlassCardPrototypeFieldState = .sample
    @State private var leftBottomState: GlassCardPrototypeFieldState = .sample
    @State private var rightTopState: GlassCardPrototypeFieldState = .sample
    @State private var rightBottomState: GlassCardPrototypeFieldState = .sample
    @State private var localPhoto: UIImage?
    @State private var localPhotoAspectRatio: CGFloat?
    @State private var usesLocalPhoto = false
    @State private var artifactImage: CGImage?
    @State private var previewCanvasSize: CGSize = .zero
    @State private var artifactKey: String?
    @State private var artifactMessage: String?

    let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        if ProcessInfo.processInfo.arguments.contains("--glasscard-artifact-review") {
            _surfaceCandidate = State(initialValue: .fixedAlpha)
        }
        if ProcessInfo.processInfo.arguments.contains("--glasscard-long-text-review") {
            _leftTopState = State(initialValue: .longChinese)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    introduction

                    fieldStateControls

                    if localPhoto != nil {
                        Toggle("使用本地 Live Photo 原片", isOn: $usesLocalPhoto)
                    }

                    Picker("验证背景", selection: $scene) {
                        ForEach(GlassCardPrototypeSceneKind.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("文字样例", selection: $textFixture) {
                        ForEach(GlassCardPrototypeTextFixture.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("材质候选", selection: $surfaceCandidate) {
                        ForEach(GlassCardPrototypeSurfaceCandidate.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("边缘候选", selection: $edgeCandidate) {
                        ForEach(GlassCardPrototypeEdgeCandidate.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("文字候选", selection: $inkCandidate) {
                        ForEach(GlassCardPrototypeInkCandidate.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("标志与文字布局", selection: $compositionCandidate) {
                        ForEach(GlassCardPrototypeCompositionCandidate.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("字号候选", selection: $typeScale) {
                        ForEach(GlassCardPrototypeTypeScale.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("文字排布", selection: $textFitCandidate) {
                        ForEach(GlassCardPrototypeTextFitCandidate.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("照片方向", selection: $orientation) {
                        ForEach(GlassCardPrototypeOrientation.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(usesLocalPhoto)

                    preview
                    textFitFeedback

                    artifactProbe

                    Text("所有背景共用同一套外观参数；此页只验证呈现，不会写入配置或照片输出。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ConfigurationUI.appBackground)
            .navigationTitle("GlassCard 原型")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onClose) {
                        Label("返回", systemImage: "chevron.left")
                    }
                }
            }
        }
        .task {
            if ProcessInfo.processInfo.arguments.contains("--glasscard-artifact-review") {
                generateArtifactProbe()
            }
        }
        .task {
            guard ProcessInfo.processInfo.arguments.contains("--glasscard-local-photo") else {
                return
            }
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("GlassCardArtifactProbe/reference-photo.heic")
            if let image = UIImage(contentsOfFile: url.path) {
                if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                   let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
                   let rawWidth = properties[kCGImagePropertyPixelWidth as String] as? Int,
                   let rawHeight = properties[kCGImagePropertyPixelHeight as String] as? Int,
                   rawWidth > 0, rawHeight > 0 {
                    let sourceOrientation = properties[kCGImagePropertyOrientation as String] as? Int ?? 1
                    let quarterTurn = [5, 6, 7, 8].contains(sourceOrientation)
                    let displayWidth = quarterTurn ? rawHeight : rawWidth
                    let displayHeight = quarterTurn ? rawWidth : rawHeight
                    localPhotoAspectRatio = CGFloat(displayWidth) / CGFloat(displayHeight)
                    orientation = displayWidth >= displayHeight ? .landscape : .portrait
                }
                localPhoto = image
                usesLocalPhoto = true
                textFixture = .neutral
                surfaceCandidate = .fixedAlpha
            }
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("第四 Renderer · 外观研究")
                .font(.title3.weight(.semibold))
            Text("素材文字只用于校准字宽和构图；四个位置的内容含义由 MemoMark 模板决定。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var preview: some View {
        GlassCardPrototypeRenderer(
            content: content,
            badge: .appleClassic,
            appearance: appearance
        ) {
            photoContent
        }
        .aspectRatio(activeAspectRatio, contentMode: .fit)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            previewCanvasSize = size
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("GlassCard 信息条预览")
        .accessibilityIdentifier("glassCard.prototype.preview")
        .accessibilityValue(
            [
                usesLocalPhoto ? "本地 Live Photo 原片" : scene.title,
                orientation.title,
                textFixture.rawValue,
                surfaceCandidate.rawValue,
                edgeCandidate.rawValue,
                inkCandidate.rawValue,
                compositionCandidate.rawValue,
                typeScale.rawValue,
                textFitCandidate.rawValue,
                "左上区域：\(leftTopState.rawValue)",
                "左下区域：\(leftBottomState.rawValue)",
                "右上区域：\(rightTopState.rawValue)",
                "右下区域：\(rightBottomState.rawValue)"
            ].joined(separator: "，")
        )
    }

    @ViewBuilder
    private var textFitFeedback: some View {
        if compositionCandidate == .referenceArrangement, previewCanvasSize.width > 0 {
            let overflow = overflowingPositions
            Text(content.isEmpty
                 ? "四个区域均为空；当前原型保留徽标栏，全空输出规则仍待定。"
                 : overflow.isEmpty
                     ? "文字测量：四个区域在当前字号与缩放下限内完整适配。"
                     : "空间不足：\(overflow.joined(separator: "、"))。请缩短内容或调整排版；当前预览可能省略文字。")
                .font(.footnote)
                .foregroundStyle(overflow.isEmpty ? Color.secondary : Color.orange)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("glassCard.prototype.textFit")
        }
    }

    private var overflowingPositions: [String] {
        appearance.overflowingPositions(content: content, canvasSize: previewCanvasSize)
    }

    private var activeAspectRatio: CGFloat {
        usesLocalPhoto ? (localPhotoAspectRatio ?? orientation.aspectRatio) : orientation.aspectRatio
    }

    @ViewBuilder
    private var photoContent: some View {
        if usesLocalPhoto, let localPhoto {
            Image(uiImage: localPhoto)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            GlassCardSyntheticScene(kind: scene)
        }
    }

    private var appearance: GlassCardPrototypeAppearance {
        GlassCardPrototypeAppearance(
            surfaceCandidate: surfaceCandidate,
            edgeCandidate: edgeCandidate,
            inkCandidate: inkCandidate,
            typeScale: typeScale,
            textFitCandidate: textFitCandidate,
            compositionCandidate: compositionCandidate
        )
    }

    private var artifactProbe: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("生成静态图层合成样例") {
                generateArtifactProbe()
            }
            .buttonStyle(.bordered)
            .disabled(surfaceCandidate.exportRecipe == nil)

            Text(surfaceCandidate.exportRecipe.map {
                "研究配方：\($0.researchID)。通过现有 PresentationArtifact 在内存中合成，不保存照片。"
            } ?? "系统材质仅供外观参考，请选择固定透明层候选生成合成样例。")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if artifactKey == reviewStateKey, let artifactImage {
                Image(
                    artifactImage,
                    scale: 1,
                    label: Text("GlassCard 静态图层合成样例")
                )
                    .resizable()
                    .aspectRatio(activeAspectRatio, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityIdentifier("glassCard.prototype.artifact")
            }

            if artifactKey == reviewStateKey, let artifactMessage {
                Text(artifactMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var reviewStateKey: String {
        [
            scene.rawValue,
            usesLocalPhoto ? "localPhoto" : "synthetic",
            orientation.rawValue,
            textFixture.rawValue,
            surfaceCandidate.rawValue,
            edgeCandidate.rawValue,
            inkCandidate.rawValue,
            compositionCandidate.rawValue,
            typeScale.rawValue,
            textFitCandidate.rawValue,
            leftTopState.rawValue,
            leftBottomState.rawValue,
            rightTopState.rawValue,
            rightBottomState.rawValue
        ].joined(separator: "|")
    }

    @MainActor
    private func generateArtifactProbe() {
        let canvasSize: CGSize
        if usesLocalPhoto, let localPhotoAspectRatio {
            canvasSize = localPhotoAspectRatio >= 1
                ? CGSize(width: (1080 * localPhotoAspectRatio).rounded(), height: 1080)
                : CGSize(width: 1080, height: (1080 / localPhotoAspectRatio).rounded())
        } else {
            canvasSize = orientation == .portrait
                ? CGSize(width: 1080, height: 1440)
                : CGSize(width: 1920, height: 1080)
        }

        let overflow = appearance.overflowingPositions(content: content, canvasSize: canvasSize)
        guard !content.isEmpty,
              appearance.surfaceCandidate.exportRecipe != nil,
              appearance.compositionCandidate == .referenceArrangement,
              overflow.isEmpty else {
            artifactImage = nil
            artifactKey = reviewStateKey
            if content.isEmpty {
                artifactMessage = "研究样例暂不导出全空内容；正式行为待确认。"
            } else if !overflow.isEmpty {
                artifactMessage = "样例未生成：\(overflow.joined(separator: "、"))文字超出边界。"
            } else {
                artifactMessage = "当前材质或构图仅用于外观比较，暂不支持样例导出。"
            }
            return
        }

        let photoRenderer = ImageRenderer(
            content: photoContent
                .frame(width: canvasSize.width, height: canvasSize.height)
                .clipped()
        )
        photoRenderer.scale = 1
        photoRenderer.proposedSize = .init(canvasSize)
        photoRenderer.isOpaque = true

        let overlayRenderer = ImageRenderer(
            content: GlassCardPrototypeOverlay(
                content: content,
                badge: .appleClassic,
                appearance: appearance,
                canvasSize: canvasSize
            )
        )
        overlayRenderer.scale = 1
        overlayRenderer.proposedSize = .init(canvasSize)
        overlayRenderer.isOpaque = false

        guard let photo = photoRenderer.cgImage,
              let overlay = overlayRenderer.cgImage else {
            artifactImage = nil
            artifactKey = reviewStateKey
            artifactMessage = "样例生成失败：无法取得图像像素。"
            return
        }

        do {
            let bounds = CGRect(origin: .zero, size: canvasSize)
            let artifact = try PresentationArtifact(
                canvasSize: canvasSize,
                photoFrame: bounds,
                layers: [.init(frame: bounds, image: overlay, zIndex: 100)],
                canvasBackground: .transparent
            )
            guard let composed = MemoMarkRenderedImageArtifactGuard.composingSourcePhoto(
                photo,
                with: artifact
            ) else {
                artifactImage = nil
                artifactKey = reviewStateKey
                artifactMessage = "样例生成失败：静态图层合成未返回图像。"
                return
            }
            artifactImage = composed
            artifactKey = reviewStateKey
            let saved = saveArtifactProbeImages(
                photo: photo,
                overlay: overlay,
                composed: composed
            )
            artifactMessage = saved
                ? "已合成 \(composed.width) × \(composed.height) 像素样例；调试 PNG 已写入模拟器临时目录。"
                : "已在内存中合成 \(composed.width) × \(composed.height) 像素样例；调试 PNG 写入失败。"
        } catch {
            artifactImage = nil
            artifactKey = reviewStateKey
            artifactMessage = "样例生成失败：图层几何无效。"
        }
    }

    private func saveArtifactProbeImages(
        photo: CGImage,
        overlay: CGImage,
        composed: CGImage
    ) -> Bool {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GlassCardArtifactProbe", isDirectory: true)
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        } catch {
            return false
        }

        for (name, image) in [
            ("photo.png", photo),
            ("overlay.png", overlay),
            ("composed.png", composed)
        ] {
            let url = directory.appendingPathComponent(name)
            guard let destination = CGImageDestinationCreateWithURL(
                url as CFURL,
                "public.png" as CFString,
                1,
                nil
            ) else {
                return false
            }
            CGImageDestinationAddImage(destination, image, nil)
            guard CGImageDestinationFinalize(destination) else {
                return false
            }
        }
        return true
    }

    private var content: GlassCardContentProjection {
        GlassCardContentProjection(
            leftTop: leftTopState.value(sample: textFixture.leftTop),
            leftBottom: leftBottomState.value(sample: textFixture.leftBottom),
            rightTop: rightTopState.value(sample: textFixture.rightTop),
            rightBottom: rightBottomState.value(sample: textFixture.rightBottom)
        )
    }

    private var fieldStateControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("字段状态 · 独立切换")
                .font(.subheadline.weight(.semibold))

            fieldStatePicker("左上区域", selection: $leftTopState)
            fieldStatePicker("左下区域", selection: $leftBottomState)
            fieldStatePicker("右上区域", selection: $rightTopState)
            fieldStatePicker("右下区域", selection: $rightBottomState)

            HStack(spacing: 12) {
                Button("全部清空") {
                    setAllFieldStates(to: .empty)
                }
                .buttonStyle(.bordered)

                Button("恢复样例") {
                    setAllFieldStates(to: .sample)
                }
                .buttonStyle(.bordered)
            }

            Text("缺失字段提供隐藏与“未提供”两种候选；空值规则仍待产品评审。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("GlassCard 字段状态")
    }

    private func fieldStatePicker(
        _ title: String,
        selection: Binding<GlassCardPrototypeFieldState>
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker(title, selection: selection) {
                ForEach(GlassCardPrototypeFieldState.allCases) { state in
                    Text(state.rawValue).tag(state)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }
    }

    private func setAllFieldStates(to state: GlassCardPrototypeFieldState) {
        leftTopState = state
        leftBottomState = state
        rightTopState = state
        rightBottomState = state
    }
}

/// Fixtures compare visual widths. Their values do not name product fields.
private enum GlassCardPrototypeTextFixture: String, CaseIterable, Identifiable {
    case referenceWidth = "素材 P04 字宽"
    case memoMark = "MemoMark 样例"
    case neutral = "中性占位"

    var id: Self { self }

    var leftTop: String {
        switch self {
        case .referenceWidth: "iPhone 15 Pro"
        case .memoMark: "Rui"
        case .neutral: "记录此刻"
        }
    }

    var leftBottom: String {
        switch self {
        case .referenceWidth: "2026.06.19 18:11:17"
        case .memoMark: "海边散步 · 2026"
        case .neutral: "时间与回忆"
        }
    }

    var rightTop: String {
        switch self {
        case .referenceWidth: "106mm f/2.8 1/669s ISO25"
        case .memoMark: "iPhone · 24 mm"
        case .neutral: "时光记"
        }
    }

    var rightBottom: String {
        switch self {
        case .referenceWidth: "4°7′21″N 72°56′8″E"
        case .memoMark: "想起那天的晚风"
        case .neutral: "留住值得回看的瞬间"
        }
    }
}

private enum GlassCardPrototypeFieldState: String, CaseIterable, Identifiable {
    case sample = "样例"
    case empty = "空值"
    case missingHidden = "缺失 · 隐藏"
    case missingPlaceholder = "缺失 · 显示未提供"
    case longChinese = "长中文"
    case longEnglish = "长英文"

    var id: Self { self }

    func value(sample: String) -> String {
        switch self {
        case .sample: sample
        case .empty, .missingHidden: ""
        case .missingPlaceholder: "未提供"
        case .longChinese: "那天我们沿着海岸慢慢走到夕阳落下，直到海风吹凉了手中的咖啡。"
        case .longEnglish: "We walked slowly along the coast until the last light faded beyond the horizon."
        }
    }
}

private enum GlassCardPrototypeOrientation: String, CaseIterable, Identifiable {
    case landscape
    case portrait

    var id: Self { self }
    var title: String { self == .landscape ? "横图" : "竖图" }
    var aspectRatio: CGFloat { self == .landscape ? 16 / 9 : 3 / 4 }
}

private enum GlassCardPrototypeSceneKind: String, CaseIterable, Identifiable {
    case brightCoast
    case nightCity
    case personProximity
    case foliage
    case water
    case road

    var id: Self { self }

    var title: String {
        switch self {
        case .brightCoast: "明亮海岸"
        case .nightCity: "夜景"
        case .personProximity: "人物邻近"
        case .foliage: "叶片纹理"
        case .water: "水面反光"
        case .road: "道路纹理"
        }
    }

    var colors: [Color] {
        switch self {
        case .brightCoast: [.init(red: 0.70, green: 0.83, blue: 0.83), .init(red: 0.91, green: 0.77, blue: 0.57), .init(red: 0.16, green: 0.40, blue: 0.45)]
        case .nightCity: [.init(red: 0.03, green: 0.06, blue: 0.14), .init(red: 0.07, green: 0.10, blue: 0.16)]
        case .personProximity: [.init(red: 0.88, green: 0.70, blue: 0.59), .init(red: 0.32, green: 0.48, blue: 0.41)]
        case .foliage: [.init(red: 0.06, green: 0.24, blue: 0.15), .init(red: 0.36, green: 0.51, blue: 0.22)]
        case .water: [.init(red: 0.20, green: 0.57, blue: 0.68), .init(red: 0.08, green: 0.31, blue: 0.47)]
        case .road: [.init(red: 0.34, green: 0.39, blue: 0.39), .init(red: 0.18, green: 0.22, blue: 0.23)]
        }
    }
}

private struct GlassCardSyntheticScene: View {

    let kind: GlassCardPrototypeSceneKind

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: kind.colors,
                    startPoint: .top,
                    endPoint: .bottom
                )

                Canvas { context, size in
                    switch kind {
                    case .brightCoast:
                        context.fill(
                            Path(ellipseIn: CGRect(x: size.width * 0.73, y: size.height * 0.18, width: size.shortSide * 0.13, height: size.shortSide * 0.13)),
                            with: .color(.orange.opacity(0.82))
                        )
                        for index in 0..<18 {
                            let y = size.height * (0.68 + CGFloat(index % 6) * 0.025)
                            var wave = Path()
                            wave.move(to: CGPoint(x: size.width * 0.04, y: y))
                            wave.addLine(to: CGPoint(x: size.width * 0.96, y: y))
                            context.stroke(wave, with: .color(.white.opacity(0.32)), lineWidth: max(1, size.shortSide * 0.002))
                        }
                    case .nightCity:
                        for index in 0..<11 {
                            let column = CGFloat(index)
                            let width = size.width / 13
                            let height = size.height * (0.20 + CGFloat((index * 7) % 9) * 0.045)
                            let rect = CGRect(x: size.width * 0.04 + column * width, y: size.height - height, width: width * 0.82, height: height)
                            context.fill(Path(rect), with: .color(.black.opacity(0.20)))
                            for row in 0..<3 {
                                let window = CGRect(x: rect.minX + width * 0.22, y: rect.minY + height * (0.35 + CGFloat(row) * 0.20), width: width * 0.12, height: width * 0.10)
                                context.fill(Path(window), with: .color(.orange.opacity(0.82)))
                            }
                        }
                    case .personProximity:
                        let head = CGRect(x: size.width * 0.43, y: size.height * 0.20, width: size.shortSide * 0.19, height: size.shortSide * 0.19)
                        context.fill(Path(ellipseIn: head), with: .color(Color(red: 0.91, green: 0.68, blue: 0.54)))
                        let shoulders = CGRect(x: size.width * 0.22, y: size.height * 0.43, width: size.width * 0.62, height: size.height * 0.50)
                        context.fill(Path(roundedRect: shoulders, cornerRadius: size.shortSide * 0.20), with: .color(Color(red: 0.20, green: 0.31, blue: 0.40)))
                        let hair = CGRect(x: head.minX, y: head.minY - size.shortSide * 0.02, width: head.width, height: head.height * 0.48)
                        context.fill(Path(ellipseIn: hair), with: .color(Color(red: 0.16, green: 0.12, blue: 0.11)))
                    case .foliage:
                        for index in 0..<55 {
                            let column = CGFloat((index * 37) % 100) / 100
                            let row = CGFloat((index * 61) % 100) / 100
                            let diameter = size.shortSide * (0.06 + CGFloat(index % 4) * 0.018)
                            let leaf = CGRect(x: column * size.width, y: row * size.height, width: diameter * 1.45, height: diameter)
                            let shade = index.isMultiple(of: 2) ? Color.green.opacity(0.48) : Color.mint.opacity(0.24)
                            context.fill(Path(ellipseIn: leaf), with: .color(shade))
                        }
                    case .water:
                        for index in 0..<30 {
                            let row = CGFloat(index) / 30
                            var wave = Path()
                            wave.move(to: CGPoint(x: 0, y: size.height * row))
                            wave.addQuadCurve(
                                to: CGPoint(x: size.width, y: size.height * row),
                                control: CGPoint(x: size.width * 0.5, y: size.height * row + sin(row * 38) * size.shortSide * 0.035)
                            )
                            context.stroke(wave, with: .color(.white.opacity(index.isMultiple(of: 3) ? 0.38 : 0.15)), lineWidth: max(1, size.shortSide * 0.003))
                        }
                    case .road:
                        var road = Path()
                        road.move(to: CGPoint(x: size.width * 0.43, y: size.height * 0.42))
                        road.addLine(to: CGPoint(x: size.width * 0.58, y: size.height * 0.42))
                        road.addLine(to: CGPoint(x: size.width * 0.95, y: size.height))
                        road.addLine(to: CGPoint(x: size.width * 0.05, y: size.height))
                        road.closeSubpath()
                        context.fill(road, with: .color(.black.opacity(0.23)))
                        var center = Path()
                        center.move(to: CGPoint(x: size.width * 0.505, y: size.height * 0.44))
                        center.addLine(to: CGPoint(x: size.width * 0.50, y: size.height))
                        context.stroke(center, with: .color(.yellow.opacity(0.84)), style: StrokeStyle(lineWidth: max(2, size.shortSide * 0.008), lineCap: .round, dash: [size.shortSide * 0.045, size.shortSide * 0.035]))
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

private extension CGSize {
    var shortSide: CGFloat { min(width, height) }
}
#endif
