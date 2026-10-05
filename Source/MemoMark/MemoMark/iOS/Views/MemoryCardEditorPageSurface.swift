#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// A one-shot request to bring an editor section into view beside the already
/// pinned preview. It is transient interaction state, not configuration data.
struct ConfigurationEditorScrollRequest: Equatable {
    let targetID: String
    let revision: UUID
}

struct MemoryCardEditorPageSurface<
    PreviewContent: View,
    EditorContent: View,
    AccessoryContent: View
>: View {

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Environment(\.verticalSizeClass)
    private var verticalSizeClass

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    let previewPinProgress: CGFloat
    let editorRevealProgress: CGFloat
    let pageTitle: String?
    let pageSubtitle: String?
    let isPreviewVisible: Bool
    let onTogglePreview: (() -> Void)?
    let previewWidthPolicy: ConfigurationPreviewWidthPolicy
    let editorScrollRequest: ConfigurationEditorScrollRequest?
    let editorContentOwnsScrolling: Bool
    let usesSystemBottomAccessory: Bool
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
        usesSystemBottomAccessory: Bool = false,
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
        self.usesSystemBottomAccessory = usesSystemBottomAccessory
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
        // AnyLayout preserves the preview's inspection state when a wide
        // configuration changes between split and collapsed presentation.
        let usesSplit = usesSplitConfigurationLayout && isPreviewVisible
        let layout = usesSplit
            ? AnyLayout(HStackLayout(alignment: .top, spacing: 0))
            : AnyLayout(VStackLayout(spacing: 0))

        return layout {
            previewPane
                .frame(
                    maxWidth: .infinity,
                    maxHeight: usesSplit ? .infinity : nil,
                    alignment: .top
                )
                .zIndex(1)

            if usesSplit {
                Rectangle()
                    .fill(ConfigurationUI.faintHairline)
                    .frame(width: 0.5)
            }

            editorPane
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var usesSplitConfigurationLayout: Bool {
        AdaptivePageLayout.usesRegularWorkspace(
            hasRegularHorizontalSizeClass: horizontalSizeClass == .regular,
            hasRegularVerticalSizeClass: verticalSizeClass == .regular
        )
    }

    private var previewPane: some View {
        previewPaneContent
            .background(
                ConfigurationUI.appBackground
            )
    }

    @ViewBuilder
    private var previewPaneContent: some View {
        if usesCompactLandscapeFullWidthPreview {
            previewPaneCore
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(
                    .horizontal,
                    ConfigurationUI.contentColumnPadding
                )
        } else {
            previewPaneCore
                .adaptivePageContent(
                    horizontalPadding: ConfigurationUI.contentColumnPadding
                )
        }
    }

    private var previewPaneCore: some View {
        VStack(alignment: .leading, spacing: isPreviewVisible ? ConfigurationUI.contentSpacing : 0) {
            if let pageTitle, let pageSubtitle {
                ConfigurationPageHeader(
                    pageTitle,
                    subtitle: pageSubtitle,
                    previewIsVisible: onTogglePreview == nil
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
            ScrollView {
                VStack(spacing: 14) {
                    editorContent
                }
                .padding(.top, 8)
                .padding(
                    .bottom,
                    editorBottomPadding
                )
                .adaptiveScrollContent(
                    horizontalPadding: ConfigurationUI.contentColumnPadding
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
        AdaptivePageLayout.navigationStyle(
            hasRegularHorizontalSizeClass:
                horizontalSizeClass == .regular,
            hasCompactVerticalSizeClass:
                verticalSizeClass == .compact
        )
    }

    private var editorBottomPadding: CGFloat {
        usesSystemBottomAccessory
            ? 26
            : AdaptivePageLayout.scrollBottomPadding(for: navigationStyle)
    }
}
#endif
