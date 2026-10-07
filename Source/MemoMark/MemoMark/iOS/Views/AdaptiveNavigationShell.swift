#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

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
        switch navigationStyle {
        case .bottomTabBar:
            compactNavigation
        case .floatingRail:
            floatingRailNavigation
        case .regularSidebar:
            regularSidebarNavigation
        }
    }

    private var compactNavigation: some View {
        NavigationStack {
            TabView(selection: $selection) {
                homeContent
                    .tabItem {
                        Label(
                            localized("首页"),
                            systemImage: MemoMarkSymbol.home.name
                        )
                    }
                    .tag(EntryTab.home)

                editorContent
                    .tabItem {
                        Label(
                            localized("配置"),
                            systemImage:
                                MemoMarkSymbol.configurationCenter.name
                        )
                    }
                    .tag(EntryTab.editor)

                taskContent
                    .tabItem {
                        Label(
                            localized("进展"),
                            systemImage: MemoMarkSymbol.task.name
                        )
                    }
                    .tag(EntryTab.tasks)
            }
        }
    }

    private var floatingRailNavigation: some View {
        NavigationStack {
            sidebarDestination
                .environment(\.layoutDirection, contentLayoutDirection)
                // Apply the inset inside navigation's hosting boundary so the
                // destination receives the reduced safe content region.
                .safeAreaInset(edge: .trailing, spacing: ConfigurationUI.innerPanelPadding) {
                    ScrollView(.vertical) {
                        VStack(spacing: ConfigurationUI.innerPanelPadding) {
                            EntryFloatingNavigationRail(selection: $selection)
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
                            if let configurationActions {
                                configurationActions
                            }
                        }
                    }
                        // Normally centered; short keyboard/window regions can
                        // scroll the actions instead of clipping the last one.
                        .scrollIndicators(.hidden)
                        .defaultScrollAnchor(.center, for: .alignment)
                        .frame(width: 56)
                        .padding(.trailing, 10)
                        .padding(.vertical, 12)
                }
                // The rail is physically right; destination content retains
                // its own semantic reading direction for RTL languages.
                .environment(\.layoutDirection, .leftToRight)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(
            ConfigurationUI.appBackground
                .ignoresSafeArea()
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
#endif
