import SwiftUI

struct MainVariableLibraryPanel: View {

    let title: String

    let variables: [TemplateVariable]

    let isEnabled: Bool

    let onInsertVariable:
        (TemplateVariable) -> Void

    let onDismissArrangeMode: () -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text(title)
                .font(.headline)

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {

                HStack(spacing: 10) {

                    ForEach(variables) { variable in

                        Button(variable.title) {
                            onInsertVariable(variable)
                        }
                        .buttonStyle(
                            MinimalChipStyle()
                        )
                        .disabled(!isEnabled)
                    }
                }
                .padding(.vertical, 1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onDismissArrangeMode()
        }
    }
}
