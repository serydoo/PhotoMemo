#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// A one-shot request to bring an editor section into view beside the already
/// pinned preview. It is transient interaction state, not configuration data.
struct ConfigurationEditorScrollRequest: Equatable {
    let targetID: String
    let revision: UUID
}

private struct WideConfigurationPreviewPaneHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

struct MemoryCardEditorPageSurface<
    PreviewContent: View,
    EditorContent: View,
    AccessoryContent: View
>: View {

    @Environment(\.entryNavigationPresentation)
    private var navigationPresentation

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Environment(\.verticalSizeClass)
    private var verticalSizeClass

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body)
    private var minimumWideRegionWidth = WideOverviewLayoutPolicy.minimumRegionWidth

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Environment(\.configurationWindowViewport) private var windowViewport
    @ScaledMetric(relativeTo: .body)
    private var minimumWideEditorHeight = WideConfigurationRegionPolicy.minimumEditorHeight
    @ScaledMetric(relativeTo: .body)
    private var widePreviewChromeHeight = WideConfigurationRegionPolicy.previewChromeHeight

    @State private var retainedPreviewHeight: CGFloat = 0
    @State private var widePreviewPaneHeight: CGFloat = 0

    let previewPinProgress: CGFloat
    let editorRevealProgress: CGFloat
    let pageTitle: String?
    let pageSubtitle: String?
    let isPreviewVisible: Bool
    let onTogglePreview: (() -> Void)?
    let previewWidthPolicy: ConfigurationPreviewWidthPolicy
    let editorScrollRequest: ConfigurationEditorScrollRequest?
    let editorContentOwnsScrolling: Bool
    let onDismissKeyboard: () -> Void
    @ViewBuilder var previewContent: PreviewContent
    @ViewBuilder var editorContent: EditorContent
    @ViewBuilder var accessoryContent: AccessoryContent

    init(
        previewPinProgress: CGFloat,
        editorRevealProgress: CGFloat,
        pageTitle: String?,
        pageSubtitle: String?,
        isPreviewVisible: Bool = true,
        onTogglePreview: (() -> Void)? = nil,
        previewWidthPolicy: ConfigurationPreviewWidthPolicy = .readable,
        editorScrollRequest: ConfigurationEditorScrollRequest? = nil,
        editorContentOwnsScrolling: Bool = false,
        onDismissKeyboard: @escaping () -> Void,
        @ViewBuilder previewContent: () -> PreviewContent,
        @ViewBuilder editorContent: () -> EditorContent,
        @ViewBuilder accessoryContent: () -> AccessoryContent
    ) {
        self.previewPinProgress = previewPinProgress
        self.editorRevealProgress = editorRevealProgress
        self.pageTitle = pageTitle
        self.pageSubtitle = pageSubtitle
        self.isPreviewVisible = isPreviewVisible
        self.onTogglePreview = onTogglePreview
        self.previewWidthPolicy = previewWidthPolicy
        self.editorScrollRequest = editorScrollRequest
        self.editorContentOwnsScrolling = editorContentOwnsScrolling
        self.onDismissKeyboard = onDismissKeyboard
        self.previewContent = previewContent()
        self.editorContent = editorContent()
        self.accessoryContent = accessoryContent()
    }

    var body: some View {
        adaptiveContent
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top
            )
            .background(
                ConfigurationUI.appBackground
                    .ignoresSafeArea()
            )
            .coordinateSpace(name: "configuration-center-scroll")
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.2),
                value: isPreviewVisible
            )
            .safeAreaInset(edge: .bottom, spacing: 0) {
                accessoryContent
            }
    }

    private var adaptiveContent: some View {
        let compact = verticalSizeClass == .compact

        // Keep the same TextKit editor subtree across rotation. A conditional
        // ScrollView wrapper would destroy its selection, IME and undo owner.
        return GeometryReader { geometry in
            let nativeAllocation = navigationStyle == .wideTaskSpaces
                ? SystemPresentationRegions.allocation(in: geometry) : nil
            let usesSplit = nativeAllocation.map { $0.arrangement == .sideBySide } ?? (!compact && usesSplitConfigurationLayout(in: navigationStyle == .wideTaskSpaces ? (windowViewport ?? geometry.size) : geometry.size) && isPreviewVisible)
            let layout = nativeAllocation.map { AnyLayout(ReservedPresentationRegionLayout(allocation: $0)) } ?? (usesSplit
                ? AnyLayout(HStackLayout(alignment: .top, spacing: 0))
                : AnyLayout(VStackLayout(spacing: 0)))
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    layout {
                        previewPane(viewportWidth: nativeAllocation?.primary.width ?? (usesSplit && navigationStyle == .wideTaskSpaces
                            ? max(0, (geometry.size.width - 0.5) / 2) : geometry.size.width))
                            .frame(width: nativeAllocation?.primary.width ?? (usesSplit && navigationStyle == .wideTaskSpaces
                                ? max(0, (geometry.size.width - 0.5) / 2) : nil))
                            .frame(height: nativeAllocation?.primary.height)
                            .frame(maxWidth: .infinity,
                                   maxHeight: usesSplit ? .infinity : nil, alignment: .top)
                            .background {
                                if navigationStyle == .wideTaskSpaces {
                                    GeometryReader { pane in
                                        Color.clear.preference(key: WideConfigurationPreviewPaneHeightKey.self,
                                            value: pane.size.height)
                                    }
                                }
                            }
                            .environment(\.configurationPreviewMaximumHeight,
                                navigationStyle == .wideTaskSpaces
                                    ? WideConfigurationRegionPolicy.previewMaximumHeight(
                                        viewportHeight: nativeAllocation?.primary.height ?? geometry.size.height,
                                        arrangement: nativeAllocation != nil || usesSplit ? .sideBySide : .stacked,
                                        minimumEditorHeight: minimumWideEditorHeight,
                                        previewChromeHeight: widePreviewChromeHeight)
                                    : nil)
                            .zIndex(1)
                            .id("card-editor-preview-origin")

                        Rectangle()
                            .fill(ConfigurationUI.faintHairline)
                            .frame(width: usesSplit ? 0.5 : 0,
                                   height: usesSplit ? geometry.size.height : 0)
                            .accessibilityHidden(true)

                        editorPane
                            .frame(width: nativeAllocation?.secondary.width ?? (usesSplit && navigationStyle == .wideTaskSpaces
                                ? max(0, (geometry.size.width - 0.5) / 2) : nil))
                            .frame(height: nativeAllocation?.secondary.height ?? (compact
                                ? max(0, geometry.size.height - (isPreviewVisible ? retainedPreviewHeight + 10 : 0))
                                : (navigationStyle == .wideTaskSpaces
                                    ? WideConfigurationRegionPolicy.editorHeight(viewportHeight: geometry.size.height,
                                        previewPaneHeight: widePreviewPaneHeight,
                                        arrangement: usesSplit ? .sideBySide : .stacked)
                                    : nil)))
                            .frame(maxWidth: .infinity, maxHeight: compact ? nil : .infinity)
                            .id("card-editor-scroll-destination")
                    }
                    .frame(height: nativeAllocation != nil || !compact ? geometry.size.height : nil, alignment: .top)
                }
                .scrollDismissesKeyboard(.never)
                .onPreferenceChange(WideConfigurationPreviewPaneHeightKey.self) { widePreviewPaneHeight = $0 }
                .onPreferenceChange(CardEditorRetainedPreviewHeightKey.self) { retainedPreviewHeight = $0 }
                .onChange(of: verticalSizeClass) { _, sizeClass in
                    if sizeClass != .compact {
                        proxy.scrollTo("card-editor-preview-origin", anchor: .top)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                    guard compact && editorContentOwnsScrolling else { return }
                    if reduceMotion {
                        proxy.scrollTo("card-editor-scroll-destination", anchor: .bottom)
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo("card-editor-scroll-destination", anchor: .bottom)
                        }
                    }
                }
                .accessibilityIdentifier("card-editor-scrolling-preview")
            }
        }
    }

    private func usesSplitConfigurationLayout(in viewport: CGSize) -> Bool {
        let hasPeerCapacity = ConfigurationContentArrangementPolicy.arrangement(for: AdaptivePresentationCapabilities(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )) == .sideBySide
        guard hasPeerCapacity, !dynamicTypeSize.isAccessibilitySize else { return false }
        return WideConfigurationLayoutPolicy.arrangement(viewport: viewport,
            minimumRegionWidth: minimumWideRegionWidth) == .sideBySide
    }

    private func previewPane(viewportWidth: CGFloat) -> some View {
        previewPaneContent(viewportWidth: viewportWidth)
            .background(
                ConfigurationUI.appBackground
            )
    }

    @ViewBuilder
    private func previewPaneContent(viewportWidth: CGFloat) -> some View {
        if usesCompactLandscapeFullWidthPreview {
            previewPaneCore
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(
                    .horizontal,
                    ConfigurationUI.contentColumnPadding
                )
        } else {
            previewPaneCore.adaptiveScrollContent(
                horizontalPadding: ConfigurationUI.contentColumnPadding,
                viewportWidth: viewportWidth,
                fillsAvailableWidth: verticalSizeClass == .compact
            )
        }
    }

    private var previewPaneCore: some View {
        VStack(alignment: .leading, spacing: isPreviewVisible ? ConfigurationUI.contentSpacing : 0) {
            if let pageTitle, let pageSubtitle {
                ConfigurationPageHeader(
                    pageTitle,
                    subtitle: pageSubtitle,
                    previewIsVisible: onTogglePreview == nil || navigationStyle == .floatingRail
                        ? nil
                        : isPreviewVisible,
                    onTogglePreview: onTogglePreview
                )
            }

            previewContent
                .frame(
                    maxWidth: .infinity,
                    alignment: .center
                )
                // Keep inspection state alive while releasing all preview height.
                .frame(height: isPreviewVisible ? nil : 0)
                .clipped()
                .opacity(isPreviewVisible ? 1 : 0)
                .allowsHitTesting(isPreviewVisible)
                .accessibilityHidden(!isPreviewVisible)
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    private var usesCompactLandscapeFullWidthPreview: Bool {
        previewWidthPolicy == .fullWidthInCompactLandscape
            && horizontalSizeClass == .regular
            && verticalSizeClass == .compact
    }

    private var editorScrollView: some View {
        ScrollViewReader { proxy in
            GeometryReader { viewport in
                ScrollView {
                    VStack(spacing: 14) {
                        editorContent
                    }
                    .padding(.top, 8)
                    .padding(
                        .bottom,
                        NavigationPresentationPolicy.scrollBottomPadding(for: navigationStyle)
                    )
                    .adaptiveScrollContent(
                        horizontalPadding: ConfigurationUI.contentColumnPadding,
                        viewportWidth: viewport.size.width,
                        fillsAvailableWidth: verticalSizeClass == .compact
                    )
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: editorScrollRequest) { _, request in
                    guard let request else { return }

                    Task { @MainActor in
                        // Wait for the disclosure and expanded calibration canvas
                        // to settle, then present its controls directly below the
                        // fixed preview. The person owns scrolling after this.
                        if !reduceMotion {
                            try? await Task.sleep(nanoseconds: 220_000_000)
                        }
                        guard editorScrollRequest == request else { return }

                        if reduceMotion {
                            proxy.scrollTo(request.targetID, anchor: .top)
                        } else {
                            withAnimation(.easeInOut(duration: 0.22)) {
                                proxy.scrollTo(request.targetID, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var editorPane: some View {
        if editorContentOwnsScrolling {
            editorContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            editorScrollView
        }
    }

    private var navigationStyle:
        EntryNavigationStyle {
        navigationPresentation ?? NavigationPresentationPolicy.style(for: AdaptivePresentationCapabilities(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        ))
    }

}
#endif
