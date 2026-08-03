#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1EntryNavigationSurface<
    HomeContent: View,
    EditorContent: View,
    OutputContent: View,
    TaskContent: View,
    SettingsContent: View
>: View {

    let navigationStyle: V1EntryNavigationStyle

    @Binding
    var selection: V1EntryTab

    private let homeContent: HomeContent
    private let editorContent: EditorContent
    private let outputContent: OutputContent
    private let taskContent: TaskContent
    private let settingsContent: SettingsContent

    init(
        navigationStyle: V1EntryNavigationStyle,
        selection: Binding<V1EntryTab>,
        @ViewBuilder homeContent: () -> HomeContent,
        @ViewBuilder editorContent: () -> EditorContent,
        @ViewBuilder outputContent: () -> OutputContent,
        @ViewBuilder taskContent: () -> TaskContent,
        @ViewBuilder settingsContent: () -> SettingsContent
    ) {
        self.navigationStyle = navigationStyle
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
        case .compactSidebar:
            compactSidebarNavigation
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
                            "首页",
                            systemImage: MemoMarkSymbol.home.name
                        )
                    }
                    .tag(V1EntryTab.home)

                editorContent
                    .tabItem {
                        Label(
                            "配置",
                            systemImage:
                                MemoMarkSymbol.configurationCenter.name
                        )
                    }
                    .tag(V1EntryTab.editor)

                outputContent
                    .tabItem {
                        Label(
                            "保存",
                            systemImage: MemoMarkSymbol.output.name
                        )
                    }
                    .tag(V1EntryTab.output)

                taskContent
                    .tabItem {
                        Label(
                            "进展",
                            systemImage: MemoMarkSymbol.task.name
                        )
                    }
                    .tag(V1EntryTab.tasks)
            }
        }
    }

    private var compactSidebarNavigation: some View {
        sidebarNavigation(width: 64) {
            V1EntryCompactSidebar(selection: $selection)
        }
    }

    private var regularSidebarNavigation: some View {
        sidebarNavigation(width: 220) {
            V1EntrySidebar(selection: $selection)
        }
    }

    private func sidebarNavigation<Sidebar: View>(
        width: CGFloat,
        @ViewBuilder sidebar: () -> Sidebar
    ) -> some View {
        HStack(spacing: 0) {
            sidebar()
                .frame(width: width)

            Rectangle()
                .fill(ConfigurationUI.faintHairline)
                .frame(width: 0.5)

            NavigationStack {
                sidebarDestination
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .leading
        )
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

struct V1EntryCompactSidebar: View {

    @Binding
    var selection: V1EntryTab

    var body: some View {
        VStack(spacing: 12) {
            ForEach(V1EntryTab.allCases) { destination in
                Button {
                    selection = destination
                } label: {
                    Image(systemName: destination.symbolName)
                        .font(.system(size: 19, weight: .semibold))
                        .frame(width: 48, height: 48)
                        .foregroundStyle(
                            selection == destination
                            ? Color.accentColor
                            : Color.secondary
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
                .accessibilityLabel(destination.title)
                .accessibilityAddTraits(
                    selection == destination
                    ? .isSelected
                    : []
                )
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .padding(.vertical, 12)
        .background(ConfigurationUI.appBackground)
    }
}

struct V1EntrySidebar: View {

    @Binding
    var selection: V1EntryTab

    var body: some View {
        ZStack(alignment: .topLeading) {
            ConfigurationUI.appBackground

            Text("时光记")
                .font(.headline.weight(.semibold))
                .padding(.horizontal, 20)
                .padding(.top, 18)

            VStack(spacing: 10) {
                ForEach(V1EntryTab.allCases) { destination in
                    Button {
                        selection = destination
                    } label: {
                        Label(
                            destination.title,
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
                    .accessibilityLabel(destination.title)
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

extension V1EntryTab {

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
