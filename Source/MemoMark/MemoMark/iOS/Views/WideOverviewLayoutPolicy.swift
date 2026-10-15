#if !MEMOMARK_SHARE_EXTENSION
import CoreGraphics

/// Content-capacity thresholds, independent of device model and navigation chrome.
enum OverviewContentArrangement: Equatable, Sendable {
    case horizontal
    case vertical
}

enum WideOverviewLayoutPolicy {
    static let minimumRegionWidth: CGFloat = 350
    static let minimumViewportWidth: CGFloat = 700
    static let minimumViewportHeight: CGFloat = 640
    static let regionHorizontalPadding: CGFloat = 16
    static let regionSpacing: CGFloat = 12

    static func arrangement(
        viewport: CGSize,
        hasRegularHorizontalSizeClass: Bool,
        hasRegularVerticalSizeClass: Bool,
        usesAccessibilityText: Bool,
        minimumRegionWidth: CGFloat = minimumRegionWidth
    ) -> OverviewContentArrangement? {
        guard hasRegularHorizontalSizeClass, hasRegularVerticalSizeClass,
              !usesAccessibilityText,
              viewport.width.isFinite, viewport.height.isFinite,
              minimumRegionWidth.isFinite, minimumRegionWidth > 0,
              viewport.width >= max(minimumViewportWidth, minimumRegionWidth + regionHorizontalPadding * 2),
              viewport.height >= minimumViewportHeight else { return nil }

        let horizontalCapacity = (minimumRegionWidth + regionHorizontalPadding * 2) * 2 + regionSpacing
        if viewport.width > viewport.height && viewport.width >= horizontalCapacity {
            return .horizontal
        }
        return .vertical
    }
}

/// A wide window may stack configuration independently of Overview's arrangement.
enum WideConfigurationLayoutPolicy {
    static func arrangement(viewport: CGSize,
        minimumRegionWidth: CGFloat = WideOverviewLayoutPolicy.minimumRegionWidth) -> ConfigurationContentArrangement {
        let requiredWidth = (minimumRegionWidth + WideOverviewLayoutPolicy.regionHorizontalPadding * 2) * 2
        guard viewport.width.isFinite, viewport.height.isFinite,
              minimumRegionWidth.isFinite, minimumRegionWidth > 0,
              viewport.height > 0, viewport.width > viewport.height,
              viewport.width >= requiredWidth else { return .stacked }
        return .sideBySide
    }
}

/// Presentation allocation only; the production card geometry remains unchanged.
enum WideConfigurationRegionPolicy {
    static let minimumEditorHeight: CGFloat = 260
    static let previewChromeHeight: CGFloat = 84

    static func previewMaximumHeight(viewportHeight: CGFloat,
        arrangement: ConfigurationContentArrangement,
        minimumEditorHeight: CGFloat = minimumEditorHeight,
        previewChromeHeight: CGFloat = previewChromeHeight) -> CGFloat {
        guard viewportHeight.isFinite, viewportHeight > 0,
              minimumEditorHeight.isFinite, minimumEditorHeight > 0,
              previewChromeHeight.isFinite, previewChromeHeight >= 0 else { return 0 }
        let paneBudget = arrangement == .sideBySide ? viewportHeight
            : min(viewportHeight / 2, viewportHeight - minimumEditorHeight)
        return max(0, paneBudget - previewChromeHeight)
    }

    static func editorHeight(viewportHeight: CGFloat, previewPaneHeight: CGFloat,
        arrangement: ConfigurationContentArrangement) -> CGFloat {
        guard viewportHeight.isFinite, viewportHeight > 0 else { return 0 }
        guard arrangement == .stacked else { return viewportHeight }
        let measuredPreview = previewPaneHeight.isFinite ? max(0, previewPaneHeight) : 0
        return min(viewportHeight, max(ConfigurationUI.minimumInteractiveHeight, viewportHeight - measuredPreview))
    }
}

enum WidePresentationTaskSpace: CaseIterable, Hashable, Sendable {
    case overview
    case configuration
}

/// A UI projection only: canonical EntryTab still owns routes and deep links.
enum WideTaskSpaceProjection {
    static func space(for destination: EntryTab) -> WidePresentationTaskSpace? {
        switch destination {
        case .home, .tasks: return .overview
        case .editor: return .configuration
        case .output, .settings: return nil
        }
    }

    static func destination(for space: WidePresentationTaskSpace) -> EntryTab {
        switch space {
        case .overview: return .home
        case .configuration: return .editor
        }
    }

    static func primaryTab(for destination: EntryTab, usesWidePresentation: Bool) -> EntryTab {
        usesWidePresentation && destination == .tasks ? .home : destination
    }
}
#endif
