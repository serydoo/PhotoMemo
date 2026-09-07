#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit

struct MemoryCardEditorPreviewFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        guard !next.isEmpty else { return }
        value = next
    }
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

    let previewPinProgress: CGFloat
    let editorRevealProgress: CGFloat
    let pageTitle: String
    let pageSubtitle: String
    let previewWidthPolicy: ConfigurationPreviewWidthPolicy
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
        self.onDismissKeyboard = onDismissKeyboard
        self.previewContent = previewContent()
        self.editorContent = editorContent()
        self.accessoryContent = accessoryContent()
    }

    var body: some View {
        stackedContent
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

    private var stackedContent: some View {
        VStack(spacing: 0) {
            previewPane
                .zIndex(1)

            editorScrollView
        }
    }

    private var previewPane: some View {
        previewPaneContent
            .background(
                ConfigurationUI.appBackground
            )
            .overlay {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: MemoryCardEditorPreviewFramePreferenceKey.self,
                        value: proxy.frame(in: .global)
                    )
                }
            }
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
            && UIDevice.current.userInterfaceIdiom == .phone
            && horizontalSizeClass == .regular
            && verticalSizeClass == .compact
    }

    private var editorScrollView: some View {
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
    }

    private var navigationStyle:
        EntryNavigationStyle {
        AdaptivePageLayout.navigationStyle(
            isPad:
                UIDevice.current
                .userInterfaceIdiom == .pad,
            hasRegularHorizontalSizeClass:
                horizontalSizeClass == .regular,
            hasCompactVerticalSizeClass:
                verticalSizeClass == .compact
        )
    }
}
#endif
