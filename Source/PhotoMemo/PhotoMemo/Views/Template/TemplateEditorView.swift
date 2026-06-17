import SwiftUI

struct TemplateEditorView: View {

    @State
    private var content = """
{{model}}

{{year}}-{{month}}-{{day}}

{{location}}

{{anchor_primary}}
"""

    @State
    private var previewText = ""

    @State
    private var showVariablePicker = false

    private let variableEngine =
        TemplateVariableEngine()

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            header

            editor

            Divider()

            previewSection
        }
        .padding()
        .onAppear {

            refreshPreview()
        }
        .sheet(
            isPresented: $showVariablePicker
        ) {

            NavigationStack {

                TemplateVariablePickerView {

                    variable in

                    insert(
                        variable.token
                    )

                    showVariablePicker = false

                    refreshPreview()
                }
            }
            .frame(
                minWidth: 500,
                minHeight: 600
            )
        }
    }
}

private extension TemplateEditorView {

    var header: some View {

        HStack {

            Text("Template")

            Spacer()

            Button {

                showVariablePicker = true

            } label: {

                Label(
                    "Insert Variable",
                    systemImage: "plus.circle"
                )
            }

            Button {

                refreshPreview()

            } label: {

                Label(
                    "Refresh",
                    systemImage: "arrow.clockwise"
                )
            }
        }
    }

    var editor: some View {

        TextEditor(
            text: $content
        )
        .frame(
            minHeight: 220
        )
    }

    var previewSection: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text("Preview")

            ScrollView {

                Text(previewText)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
    }

    func insert(
        _ token: String
    ) {

        if content.isEmpty {

            content = token

        } else {

            content += "\n" + token
        }
    }

    func refreshPreview() {

        let context =
            sampleContext()

        previewText =
            variableEngine.render(
                content,
                context: context
            )
    }

    func sampleContext() -> MetadataContext {

        MetadataContext(
            values: [

                "brand":
                    "Apple",

                "model":
                    "iPhone 17 Pro Max",

                "lens":
                    "24mm",

                "iso":
                    "80",

                "aperture":
                    "1.8",

                "shutter":
                    "1/250",

                "year":
                    "2026",

                "month":
                    "06",

                "day":
                    "17",

                "hour":
                    "01",

                "minute":
                    "58",

                "location":
                    "Yongcheng",

                "anchor_primary":
                    "5 Years 22 Days",

                "story":
                    "First Family Trip"
            ]
        )
    }
}

#Preview {

    TemplateEditorView()
}
