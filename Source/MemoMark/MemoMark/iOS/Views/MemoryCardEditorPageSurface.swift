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
    let pageTitle: String
    let pageSubtitle: String
    let previewWidthPolicy: ConfigurationPreviewWidthPolicy
    let editorScrollRequest: ConfigurationEditorScrollRequest?
    let onDismissKeyboard: () -> Void
    @ViewBuilder var previewContent: PreviewContent
    @ViewBuilder var editorContent: EditorContent
    @ViewBuilder var accessoryContent: AccessoryContent

    init(
        previewPinProgress: CGFloat,
        editorRevealProgress: CGFloat,
        pageTitle: String,
        pageSubtitle: String,
        previewWidthPolicy: ConfigurationPreviewWidthPolicy = .readable,
        editorScrollRequest: ConfigurationEditorScrollRequest? = nil,
        onDismissKeyboard: @escaping () -> Void,
        @ViewBuilder previewContent: () -> PreviewContent,
        @ViewBuilder editorContent: () -> EditorContent,
        @ViewBuilder accessoryContent: () -> AccessoryContent
    ) {
        self.previewPinProgress = previewPinProgress
        self.editorRevealProgress = editorRevealProgress
        self.pageTitle = pageTitle
        self.pageSubtitle = pageSubtitle
        self.previewWidthPolicy = previewWidthPolicy
        self.editorScrollRequest = editorScrollRequest
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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                accessoryContent
            }
    }

    @ViewBuilder
    private var adaptiveContent: some View {
        if usesSplitConfigurationLayout {
            sideBySideContent
        } else {
            stackedContent
        }
    }

    private var usesSplitConfigurationLayout: Bool {
        AdaptivePageLayout.usesRegularWorkspace(
            hasRegularHorizontalSizeClass: horizontalSizeClass == .regular,
            hasRegularVerticalSizeClass: verticalSizeClass == .regular
        )
    }

    private var stackedContent: some View {
        VStack(spacing: 0) {
            previewPane
                .zIndex(1)

            editorScrollView
        }
    }

    private var sideBySideContent: some View {
        HStack(alignment: .top, spacing: 0) {
            previewPane
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .top
                )

            Rectangle()
                .fill(ConfigurationUI.faintHairline)
                .frame(width: 0.5)

            editorScrollView
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
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
        VStack(alignment: .leading, spacing: 12) {
            ConfigurationPageHeader(
                pageTitle,
                subtitle: pageSubtitle
            )

            previewContent
                .frame(
                    maxWidth: .infinity,
                    alignment: .center
                )
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
                    AdaptivePageLayout
                        .scrollBottomPadding(
                            for: navigationStyle
                        )
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

    private var navigationStyle:
        EntryNavigationStyle {
        AdaptivePageLayout.navigationStyle(
            hasRegularHorizontalSizeClass:
                horizontalSizeClass == .regular,
            hasCompactVerticalSizeClass:
                verticalSizeClass == .compact
        )
    }
}
#endif
