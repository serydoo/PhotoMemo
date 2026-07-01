#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1ModuleLibrarySurface: View {

    let region: CardRegion
    let modules: [IOSInsertableModule]
    let categoryTitle: (IOSInsertableModule) -> String
    let valueText: (IOSInsertableModule) -> String
    let onSelectModule: (IOSInsertableModule) -> Void
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(modules) { module in
                        Button {
                            onSelectModule(module)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: module.systemImage)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.secondary)
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
                            }
                        }
                    }
                } header: {
                    Text("常用与模块")
                }
            }
            .navigationTitle(region.semanticTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        onClose()
                    }
                }
            }
        }
    }
}
#endif
