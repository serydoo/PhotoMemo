import CoreGraphics

enum V1EditorComposition {
    case stacked
    case sideBySide
}

enum V1AdaptivePageLayout {

    static let maximumReadableContentWidth:
        CGFloat = 720

    static let sideBySideEditorMinimumWidth:
        CGFloat = 760

    static func editorComposition(
        for availableWidth: CGFloat
    ) -> V1EditorComposition {
        availableWidth
            >= sideBySideEditorMinimumWidth
        ? .sideBySide
        : .stacked
    }

    static func usesSidebarNavigation(
        isPad: Bool,
        hasRegularHorizontalSizeClass: Bool
    ) -> Bool {
        isPad
            && hasRegularHorizontalSizeClass
    }
}

#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

extension View {

    func v1AdaptivePageContent(
        horizontalPadding: CGFloat
    ) -> some View {
        self
            .frame(
                maxWidth:
                    V1AdaptivePageLayout
                    .maximumReadableContentWidth
            )
            .frame(maxWidth: .infinity)
            .padding(
                .horizontal,
                horizontalPadding
            )
    }

    func v1AdaptiveScrollContent(
        horizontalPadding: CGFloat
    ) -> some View {
        v1AdaptivePageContent(
            horizontalPadding:
                horizontalPadding
        )
        .containerRelativeFrame(.horizontal)
    }
}
#endif
