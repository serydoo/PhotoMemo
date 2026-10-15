import CoreGraphics

/// Spatial facts projected by the platform adapter, never by a device model.
enum AdaptivePresentationSizeClass: Equatable, Sendable {
    case compact
    case regular
    case unspecified
}

/// Transient UI capabilities. These values never enter configuration or output truth.
struct AdaptivePresentationCapabilities: Equatable, Sendable {
    let prefersSideNavigation: Bool
    let supportsSideBySideConfiguration: Bool

    init(horizontal: AdaptivePresentationSizeClass, vertical: AdaptivePresentationSizeClass) {
        prefersSideNavigation = horizontal == .regular || vertical == .compact
        supportsSideBySideConfiguration = horizontal == .regular && vertical == .regular
    }
}

enum EntryNavigationStyle: Equatable, Sendable {
    case bottomTabBar
    case floatingRail
    case regularSidebar
    case wideTaskSpaces
}

/// V5.1 preserves current chrome even where future wide navigation is possible.
enum NavigationPresentationPolicy {
    static func style(for capabilities: AdaptivePresentationCapabilities) -> EntryNavigationStyle {
        capabilities.prefersSideNavigation ? .floatingRail : .bottomTabBar
    }

    static func scrollBottomPadding(for navigationStyle: EntryNavigationStyle) -> CGFloat {
        switch navigationStyle {
        case .bottomTabBar: return 96
        case .floatingRail, .regularSidebar, .wideTaskSpaces: return 26
        }
    }
}

#if !MEMOMARK_SHARE_EXTENSION
enum NativeCompactNavigationPolicy {
    static func usesFixedRail(hasVerticalToolbar: Bool, isPhone: Bool, viewport: CGSize, usesWidePresentation: Bool) -> Bool {
        hasVerticalToolbar && isPhone && !usesWidePresentation
            && viewport.width.isFinite && viewport.height.isFinite
            && viewport.width > 0 && viewport.width < WideOverviewLayoutPolicy.minimumViewportWidth
            && viewport.height > viewport.width
    }
}

#endif

enum ConfigurationContentArrangement: Equatable, Sendable {
    case stacked
    case sideBySide
}

/// Content capacity is independent of the navigation container or selected destination.
enum ConfigurationContentArrangementPolicy {
    static func arrangement(for capabilities: AdaptivePresentationCapabilities) -> ConfigurationContentArrangement {
        capabilities.supportsSideBySideConfiguration ? .sideBySide : .stacked
    }
}

#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

private struct ConfigurationWindowViewportKey: EnvironmentKey {
    static let defaultValue: CGSize? = nil
}
private struct ConfigurationPreviewMaximumHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat? = nil
}

private struct EntryNavigationPresentationKey: EnvironmentKey {
    static let defaultValue: EntryNavigationStyle? = nil
}

private struct HomeSettingsPresentedByContainerKey: EnvironmentKey {
    static let defaultValue = false
}

private struct HomePhotoPickerFooterPresentedByContainerKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var homeSettingsPresentedByContainer: Bool {
        get { self[HomeSettingsPresentedByContainerKey.self] }
        set { self[HomeSettingsPresentedByContainerKey.self] = newValue }
    }

    var configurationWindowViewport: CGSize? {
        get { self[ConfigurationWindowViewportKey.self] }
        set { self[ConfigurationWindowViewportKey.self] = newValue }
    }
    var configurationPreviewMaximumHeight: CGFloat? {
        get { self[ConfigurationPreviewMaximumHeightKey.self] }
        set { self[ConfigurationPreviewMaximumHeightKey.self] = newValue }
    }

    var homePhotoPickerFooterPresentedByContainer: Bool {
        get { self[HomePhotoPickerFooterPresentedByContainerKey.self] }
        set { self[HomePhotoPickerFooterPresentedByContainerKey.self] = newValue }
    }

    var entryNavigationPresentation: EntryNavigationStyle? {
        get { self[EntryNavigationPresentationKey.self] }
        set { self[EntryNavigationPresentationKey.self] = newValue }
    }
}

extension AdaptivePresentationCapabilities {
    init(horizontalSizeClass: UserInterfaceSizeClass?, verticalSizeClass: UserInterfaceSizeClass?) {
        self.init(horizontal: AdaptivePresentationSizeClass(horizontalSizeClass),
                  vertical: AdaptivePresentationSizeClass(verticalSizeClass))
    }
}

private extension AdaptivePresentationSizeClass {
    init(_ sizeClass: UserInterfaceSizeClass?) {
        switch sizeClass {
        case .compact: self = .compact
        case .regular: self = .regular
        case nil: self = .unspecified
        @unknown default: self = .unspecified
        }
    }
}
#endif
