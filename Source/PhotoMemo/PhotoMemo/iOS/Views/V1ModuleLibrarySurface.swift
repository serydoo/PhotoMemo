#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import UIKit

struct V1ModuleLibrarySurface: View {

    let region: CardRegion
    let modules: [IOSInsertableModule]
    let categoryTitle: (IOSInsertableModule) -> String
    let valueText: (IOSInsertableModule) -> String
    let onSelectModule: (IOSInsertableModule) -> Void
    let onClose: () -> Void

    @State private var searchText = ""

    private var filteredModules: [IOSInsertableModule] {
        guard !searchText.isEmpty else { return modules }
        return modules.filter { module in
            module.title.localizedStandardContains(searchText)
            || categoryTitle(module).localizedStandardContains(searchText)
            || valueText(module).localizedStandardContains(searchText)
        }
    }

    private var groupedModules: [ModuleGroup] {
        let categoryTitles = filteredModules.reduce(into: [String]()) {
            titles, module in
            let title = categoryTitle(module)
            if !titles.contains(title) {
                titles.append(title)
            }
        }

        return categoryTitles.map { title in
            ModuleGroup(
                title: title,
                modules: filteredModules.filter {
                    categoryTitle($0) == title
                }
            )
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedModules) { group in
                    Section {
                        ForEach(group.modules) { module in
                            Button {
                                UISelectionFeedbackGenerator()
                                    .selectionChanged()
                                onSelectModule(module)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: module.systemImage)
                                        .font(.body.weight(.semibold))
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(Color.accentColor)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(module.title)
                                            .font(.body)
                                            .foregroundStyle(.primary)

                                        Text(valueText(module))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }

                                    Spacer(minLength: 0)

                                    Image(
                                        systemName: "plus.circle.fill"
                                    )
                                    .font(.body.weight(.semibold))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(Color.accentColor)
                                    .accessibilityHidden(true)
                                }
                                .contentShape(Rectangle())
                            }
                        }
                    } header: {
                        Text(group.title)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索内容")
            .overlay {
                if filteredModules.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .navigationTitle(region.semanticTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        onClose()
                    }
                }
            }
        }
    }
}

private extension V1ModuleLibrarySurface {

    struct ModuleGroup: Identifiable {
        let title: String
        let modules: [IOSInsertableModule]

        var id: String {
            title
        }
    }
}
#endif
