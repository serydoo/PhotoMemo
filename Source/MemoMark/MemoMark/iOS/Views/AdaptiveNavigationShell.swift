#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit

/// A contextual viewing action, separate from primary destination navigation.
struct ConfigurationPreviewRailControl {
    let isVisible: Bool
    let toggle: () -> Void
}

struct EntryNavigationSurface<
    HomeContent: View,
    EditorContent: View,
    OutputContent: View,
    TaskContent: View,
    SettingsContent: View
>: View {

    let navigationStyle: EntryNavigationStyle
    @Environment(\.layoutDirection) private var contentLayoutDirection
    @State private var railWindowGeometry: FloatingRailWindowGeometry?
    private let previewControl: ConfigurationPreviewRailControl?
    private let configurationActions: ConfigurationActionFooter?

    @Binding
    var selection: EntryTab

    private let homeContent: HomeContent
    private let editorContent: EditorContent
    private let outputContent: OutputContent
    private let taskContent: TaskContent
    private let settingsContent: SettingsContent

    private func localized(_ value: String) -> String {
        MemoMarkLanguage.interfaceStored.localized(key: value, fallback: value)
    }

    init(
        navigationStyle: EntryNavigationStyle,
        selection: Binding<EntryTab>,
        previewControl: ConfigurationPreviewRailControl? = nil,
        configurationActions: ConfigurationActionFooter? = nil,
        @ViewBuilder homeContent: () -> HomeContent,
        @ViewBuilder editorContent: () -> EditorContent,
        @ViewBuilder outputContent: () -> OutputContent,
        @ViewBuilder taskContent: () -> TaskContent,
        @ViewBuilder settingsContent: () -> SettingsContent
    ) {
        self.navigationStyle = navigationStyle
        self.previewControl = previewControl
        self.configurationActions = configurationActions
        _selection = selection
        self.homeContent = homeContent()
        self.editorContent = editorContent()
        self.outputContent = outputContent()
        self.taskContent = taskContent()
        self.settingsContent = settingsContent()
    }

    var body: some View {
        if navigationStyle == .regularSidebar {
            regularSidebarNavigation
        } else {
            primaryNavigation
        }
    }

    private var primaryTabs: some View {
        TabView(selection: $selection) {
            homeContent
                .toolbar(navigationStyle == .bottomTabBar ? .visible : .hidden, for: .tabBar)
                .tabItem {
                    Label(
                        localized("首页"),
                        systemImage: MemoMarkSymbol.home.name
                    )
                }
                .tag(EntryTab.home)

            editorContent
                .toolbar(navigationStyle == .bottomTabBar ? .visible : .hidden, for: .tabBar)
                .tabItem {
                    Label(
                        localized("配置"),
                        systemImage:
                            MemoMarkSymbol.configurationCenter.name
                    )
                }
                .tag(EntryTab.editor)

            taskContent
                .toolbar(navigationStyle == .bottomTabBar ? .visible : .hidden, for: .tabBar)
                .tabItem {
                    Label(
                        localized("进展"),
                        systemImage: MemoMarkSymbol.task.name
                    )
                }
                .tag(EntryTab.tasks)
        }
    }

    private var primaryNavigation: some View {
        NavigationStack {
            // One shell owns the rail's width. Destinations receive the
            // remaining safe viewport and must not subtract the rail again.
            HStack(spacing: navigationStyle == .floatingRail ? AdaptiveFloatingRailMetrics.contentSpacing : 0) {
                Group {
                    if selection == .settings || selection == .output {
                        sidebarDestination
                    } else {
                        // Rotation changes only chrome. Keep the same TabView and
                        // hosting controllers so TextKit retains its input owner.
                        primaryTabs
                    }
                }
                .environment(\.layoutDirection, contentLayoutDirection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                if navigationStyle == .floatingRail {
                    // Equal contextual slots keep the primary capsule centered
                    // independently of which destination contributes actions.
                    VStack(spacing: ConfigurationUI.innerPanelPadding) {
                        ScrollView(.vertical) {
                            if let previewControl {
                                Button(action: previewControl.toggle) {
                                    Image(systemName: previewControl.isVisible
                                        ? "eye.slash" : "eye")
                                        .font(.system(size: 18, weight: .semibold))
                                        .frame(width: 46, height: 46)
                                        .foregroundStyle(Color.accentColor)
                                }
                                .buttonStyle(.plain)
                                .background(
                                    MemoMarkDesignTokens.SurfaceMaterial.contextual,
                                    in: Circle()
                                )
                                .accessibilityLabel(localized(previewControl.isVisible
                                    ? "configuration.preview.collapse"
                                    : "configuration.preview.expand"))
                                .accessibilityValue(localized(previewControl.isVisible
                                    ? "configuration.preview.visible"
                                    : "configuration.preview.hidden"))
                                .accessibilityIdentifier("configuration.preview.rail-visibility")
                            }
                        }
                        .scrollIndicators(.hidden)
                        .defaultScrollAnchor(.bottom, for: .alignment)
                        .frame(minHeight: 0, maxHeight: .infinity)

                        EntryFloatingNavigationRail(selection: $selection)
                            .fixedSize(horizontal: false, vertical: true)

                        ScrollView(.vertical) {
                            if let configurationActions {
                                configurationActions
                            }
                        }
                        .scrollIndicators(.hidden)
                        .defaultScrollAnchor(.top, for: .alignment)
                        .frame(minHeight: 0, maxHeight: .infinity)
                    }
                    .frame(width: AdaptiveFloatingRailMetrics.width)
                    .padding(.trailing, AdaptiveFloatingRailMetrics.trailingMargin)
                    .padding(.vertical, 12)
                }
            }
            .padding(.trailing, railTrailingInset ?? 0)
            .ignoresSafeArea(.container, edges: railTrailingInset == nil ? [] : .trailing)
                // The rail is physically right; destination content retains
                // its own semantic reading direction for RTL languages.
                .environment(\.layoutDirection, .leftToRight)
        }
        .background(FloatingRailWindowGeometryReader { geometry in
            if railWindowGeometry != geometry { railWindowGeometry = geometry }
        })
        .environment(\.entryWindowWidth, railWindowGeometry?.windowWidth ?? 0)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(
            ConfigurationUI.appBackground
                .ignoresSafeArea()
        )
    }

    private var railTrailingInset: CGFloat? {
        guard navigationStyle == .floatingRail, let geometry = railWindowGeometry else { return nil }
        return geometry.trailingSafeInset - AdaptiveFloatingRailMetrics.trailingEdgeExpansion(
            systemInset: geometry.trailingSafeInset,
            isUnobstructedLandscapeEdge: geometry.isUnobstructedTrailingEdge
        )
    }

    private var regularSidebarNavigation: some View {
        NavigationSplitView {
            List {
                Section {
                    ForEach(EntryTab.sidebarNavigationCases) { destination in
                        Button {
                            selection = destination
                        } label: {
                            Label(
                                destination.localizedTitle,
                                systemImage: destination.symbolName
                            )
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .foregroundStyle(
                                selection == destination
                                ? Color.accentColor
                                : Color.primary
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(
                            selection == destination
                            ? .isSelected
                            : []
                        )
                        .listRowBackground(
                            selection == destination
                            ? Color.accentColor.opacity(0.12)
                            : Color.clear
                        )
                    }
                }
            }
            .navigationTitle(localized("时光记"))
            .listStyle(.sidebar)
        } detail: {
            NavigationStack {
                sidebarDestination
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
        .navigationSplitViewStyle(.balanced)
        .background(
            ConfigurationUI.appBackground
                .ignoresSafeArea()
        )
    }

    @ViewBuilder
    private var sidebarDestination: some View {
        switch selection {
        case .home:
            homeContent
        case .editor:
            editorContent
        case .output:
            outputContent
        case .tasks:
            taskContent
        case .settings:
            settingsContent
        }
    }
}

struct EntryFloatingNavigationRail: View {

    @Binding
    var selection: EntryTab

    var body: some View {
        VStack(spacing: 4) {
            ForEach(EntryTab.primaryNavigationCases) { destination in
                Button {
                    selection = destination
                } label: {
                    Image(systemName: destination.symbolName)
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 46, height: 46)
                        .foregroundStyle(
                            selection == destination
                            ? Color.accentColor
                            : Color.secondary
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(destination.localizedTitle)
                .accessibilityAddTraits(
                    selection == destination
                    ? .isSelected
                    : []
                )
            }
        }
        .padding(5)
        .background(
            MemoMarkDesignTokens.SurfaceMaterial.contextual,
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(ConfigurationUI.faintHairline, lineWidth: 0.5)
        }
        .shadow(
            color: ConfigurationUI.cardShadow,
            radius: 6,
            y: 2
        )
        .accessibilityElement(children: .contain)
    }
}

struct EntrySidebar: View {

    @Binding
    var selection: EntryTab

    var body: some View {
        ZStack(alignment: .topLeading) {
            ConfigurationUI.appBackground

            Text("时光记")
                .font(.headline.weight(.semibold))
                .padding(.horizontal, 20)
                .padding(.top, 18)

            VStack(spacing: 10) {
                ForEach(EntryTab.sidebarNavigationCases) { destination in
                    Button {
                        selection = destination
                    } label: {
                        Label(
                            destination.localizedTitle,
                            systemImage: destination.symbolName
                        )
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 48)
                        .padding(.horizontal, 14)
                        .foregroundStyle(
                            selection == destination
                            ? Color.accentColor
                            : Color.primary
                        )
                        .background(
                            RoundedRectangle(
                                cornerRadius: 8,
                                style: .continuous
                            )
                            .fill(
                                selection == destination
                                ? Color.accentColor.opacity(0.12)
                                : Color.clear
                            )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(destination.localizedTitle)
                    .accessibilityAddTraits(
                        selection == destination
                        ? .isSelected
                        : []
                    )
                }
            }
            .padding(.horizontal, 12)
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .padding(.vertical, 12)
    }
}

extension EntryTab {

    var title: String {
        switch self {
        case .home:
            return "首页"
        case .editor:
            return "配置中心"
        case .output:
            return "保存"
        case .tasks:
            return "进展"
        case .settings:
            return "设置"
        }
    }

    var localizedTitle: String {
        MemoMarkLanguage.interfaceStored.localized(key: title, fallback: title)
    }

    var symbolName: String {
        switch self {
        case .home:
            return "house.fill"
        case .editor:
            return "slider.horizontal.3"
        case .output:
            return "square.and.arrow.down"
        case .tasks:
            return "checklist"
        case .settings:
            return MemoMarkSymbol.settings.name
        }
    }
}
private struct FloatingRailWindowGeometry: Equatable, Sendable {
    let windowWidth: CGFloat
    let trailingSafeInset: CGFloat
    let isUnobstructedTrailingEdge: Bool
}

/// Read the hosting scene rather than a global screen or physical-device pose.
/// UIInterfaceOrientation and UIDeviceOrientation use opposite landscape names.
private struct FloatingRailWindowGeometryReader: UIViewRepresentable {
    let onChange: (FloatingRailWindowGeometry) -> Void

    func makeUIView(context: Context) -> FloatingRailWindowProbe {
        let view = FloatingRailWindowProbe()
        view.isUserInteractionEnabled = false
        view.onChange = onChange
        return view
    }

    func updateUIView(_ view: FloatingRailWindowProbe, context: Context) {
        view.onChange = onChange
        view.reportGeometry()
    }
}

private final class FloatingRailWindowProbe: UIView {
    var onChange: ((FloatingRailWindowGeometry) -> Void)?
    private var lastGeometry: FloatingRailWindowGeometry?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        NotificationCenter.default.removeObserver(
            self, name: UIDevice.orientationDidChangeNotification, object: nil
        )
        if window != nil {
            // Opposite landscape poses can have identical bounds and insets,
            // so layout callbacks alone do not cover every scene rotation.
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(sceneGeometryMayHaveChanged),
                name: UIDevice.orientationDidChangeNotification,
                object: nil
            )
        }
        reportGeometry()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func sceneGeometryMayHaveChanged() {
        // The notification only invalidates the probe. Geometry still comes
        // exclusively from the hosting window scene, never device pose.
        reportGeometry()
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        reportGeometry()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        reportGeometry()
    }

    func reportGeometry() {
        // UIKit may still expose the preceding scene orientation during its
        // layout callbacks. Read and publish together after that pass finishes.
        Task { @MainActor [weak self] in self?.publishGeometry() }
    }

    private func publishGeometry() {
        guard let window, let scene = window.windowScene else { return }
        let geometry = FloatingRailWindowGeometry(
            windowWidth: window.bounds.width,
            trailingSafeInset: window.safeAreaInsets.right,
            isUnobstructedTrailingEdge: scene.interfaceOrientation == .landscapeRight
        )
        guard geometry != lastGeometry else { return }
        lastGeometry = geometry
        onChange?(geometry)
    }
}
#endif
