#if DEBUG && os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// A temporary, in-app design review surface that calls the same preview views
/// as Configuration Center. Its fixture state is deliberately not persisted.
struct ConfigurationPreviewReviewView: View {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State
    private var presentationStyle: RecordCardPresentationStyle = .classicWhite

    @State
    private var orientation: ConfigurationPreviewBackground.Orientation = .landscape

    @State
    private var showsFilmMarkGuides = false

    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    introduction
                    stylePicker
                    orientationHint

                    if presentationStyle == .filmMark {
                        filmMarkReviewControl
                    }

                    preview

                    Text("仅供设计评审的本地样例。这里的方向和校准显示不会保存，也不会影响照片或输出。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: 620, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ConfigurationUI.appBackground)
            .navigationTitle("预览评审")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onClose) {
                        Label("返回", systemImage: "chevron.left")
                    }
                }
            }
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("让照片里的表达看得更清楚")
                .font(.title3.weight(.semibold))
            Text("切换样式和照片方向，观察成品元素在完整画面中的位置。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var stylePicker: some View {
        Picker("表达样式", selection: $presentationStyle) {
            ForEach(RecordCardPresentationStyle.allCases, id: \.self) { style in
                Text(title(for: style)).tag(style)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityHint("选择经典白、极简或 FilmMark 预览")
    }

    private var orientationHint: some View {
        Text(
            orientation == .landscape
                ? "横图 · 使用左右按钮查看竖图"
                : "竖图 · 使用左右按钮查看横图"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("照片预览方向")
        .accessibilityValue(orientation == .landscape ? "横图" : "竖图")
    }

    private var filmMarkReviewControl: some View {
        Toggle("精细查看位置与字号", isOn: $showsFilmMarkGuides)
            .font(.subheadline)
            .accessibilityHint("显示 FilmMark 完整画布上的安全区和位置参考线")
    }

    private var preview: some View {
        MemoryCardPreviewSurface(
            presentationStyle: presentationStyle,
            logoMode: .appleMini,
            customLogoImagePath: nil,
            subjectAvatarLogoImagePath: nil,
            regionText: "时光记",
            timeText: "出生第 428 天",
            contextText: "2026年6月18日 · 横滨",
            memoryText: "你第一次追着风跑",
            filmMarkOutputText: "2026.06.18 · 出生第 428 天",
            filmMarkConfiguration: .default,
            filmMarkPreviewMode: .fullPhotoCanvas(
                orientation: orientation,
                showsGuides: showsFilmMarkGuides
            ),
            previewOrientation: orientation
        )
        .frame(maxWidth: .infinity)
        .aspectRatio(previewAspectRatio, contentMode: .fit)
        .contentShape(Rectangle())
        .accessibilityIdentifier("configuration.previewReview.surface")
        .accessibilityValue(orientation == .landscape ? "横图" : "竖图")
        .accessibilityAction(
            named: Text(
                orientation == .landscape ? "切换为竖图" : "切换为横图"
            )
        ) {
            orientation = orientation == .landscape ? .portrait : .landscape
        }
        .overlay(alignment: .leading) {
            orientationArrowButton(systemImage: "chevron.left")
                .padding(.leading, 6)
        }
        .overlay(alignment: .trailing) {
            orientationArrowButton(systemImage: "chevron.right")
                .padding(.trailing, 6)
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.2),
            value: orientation
        )
    }

    private var previewAspectRatio: CGFloat {
        switch presentationStyle {
        case .classicWhite:
            ConfigurationPreviewViewportSpec.canvasAspectRatio(
                for: .classicWhite,
                orientation: orientation
            )
        case .minimal:
            ConfigurationPreviewBackground.aspectRatio(for: orientation)
        case .filmMark:
            ConfigurationPreviewBackground.aspectRatio(for: orientation)
        }
    }

    private func orientationArrowButton(systemImage: String) -> some View {
        Button {
            orientation = orientation == .landscape ? .portrait : .landscape
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.96))
                .frame(width: 44, height: 44)
                .shadow(color: .black.opacity(0.28), radius: 1, y: 1)
                .modifier(ReviewPreviewControlGlass())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            orientation == .landscape ? "切换为竖图" : "切换为横图"
        )
    }

    private func title(for style: RecordCardPresentationStyle) -> String {
        switch style {
        case .classicWhite:
            "经典白"
        case .minimal:
            "极简"
        case .filmMark:
            "FilmMark"
        }
    }
}

private struct ReviewPreviewControlGlass: ViewModifier {

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: Circle())
        } else {
            content
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.30), lineWidth: 0.7)
                }
        }
    }
}
#endif
