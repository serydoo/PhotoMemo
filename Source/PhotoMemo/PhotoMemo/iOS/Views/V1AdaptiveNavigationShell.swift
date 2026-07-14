#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

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
            return "输出"
        case .tasks:
            return "任务"
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
