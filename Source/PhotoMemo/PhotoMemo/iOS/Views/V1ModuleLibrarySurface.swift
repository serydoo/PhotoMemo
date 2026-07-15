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

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(filteredModules) { module in
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

                                    HStack(spacing: 6) {
                                        Text(categoryTitle(module))
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.tertiary)
                                            .textCase(.uppercase)

                                        Text(valueText(module))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
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
                    Text("常用与模块")
                }
            }
            .searchable(text: $searchText, prompt: "搜索模块")
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
#endif
