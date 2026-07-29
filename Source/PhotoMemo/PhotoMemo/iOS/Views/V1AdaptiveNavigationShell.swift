#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1EntryNavigationSurface<
    HomeContent: View,
    EditorContent: View,
    OutputContent: View,
    TaskContent: View,
    SettingsContent: View
>: View {

    let usesSidebarNavigation: Bool

    @Binding
    var selection: V1EntryTab

    private let homeContent: HomeContent
    private let editorContent: EditorContent
    private let outputContent: OutputContent
    private let taskContent: TaskContent
    private let settingsContent: SettingsContent

    init(
        usesSidebarNavigation: Bool,
        selection: Binding<V1EntryTab>,
        @ViewBuilder homeContent: () -> HomeContent,
        @ViewBuilder editorContent: () -> EditorContent,
        @ViewBuilder outputContent: () -> OutputContent,
        @ViewBuilder taskContent: () -> TaskContent,
        @ViewBuilder settingsContent: () -> SettingsContent
    ) {
        self.usesSidebarNavigation = usesSidebarNavigation
        _selection = selection
        self.homeContent = homeContent()
        self.editorContent = editorContent()
        self.outputContent = outputContent()
        self.taskContent = taskContent()
        self.settingsContent = settingsContent()
    }

    var body: some View {
        if usesSidebarNavigation {
            regularNavigation
        } else {
            compactNavigation
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

    private var regularNavigation: some View {
        HStack(spacing: 0) {
            V1EntrySidebar(selection: $selection)
                .frame(width: 220)

            Rectangle()
                .fill(ConfigurationUI.faintHairline)
                .frame(width: 0.5)

            NavigationStack {
                regularDestination
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
        .background(
            ConfigurationUI.appBackground
                .ignoresSafeArea()
        )
    }

    @ViewBuilder
    private var regularDestination: some View {
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

struct V1EntrySidebar: View {

    @Binding
    var selection: V1EntryTab

    var body: some View {
        List(
            V1EntryTab.allCases,
            selection: selectionBinding
        ) { destination in
            Label(
                destination.title,
                systemImage: destination.symbolName
            )
            .tag(destination)
        }
        .navigationTitle("时光记")
        .listStyle(.sidebar)
    }

    private var selectionBinding:
        Binding<V1EntryTab?> {
        Binding(
            get: { selection },
            set: { destination in
                if let destination {
                    selection = destination
                }
            }
        )
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
