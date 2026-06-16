import SwiftUI
import PhotosUI
import AppKit

struct MainView: View {

    @StateObject
    private var settingsService = SettingsService()

    @State
    private var selectedItem: PhotosPickerItem?

    @State
    private var selectedImage: Image?

    @State
    private var anchorResult = AnchorResult(
        title: "",
        primaryText: "",
        secondaryText: ""
    )

    private let anchorEngine = AnchorEngine()

    var body: some View {

        NavigationStack {

            VStack(spacing: 24) {

                previewArea

                templateSection

                photoPicker

                generateButton
            }
            .padding()
            .navigationTitle("PhotoMemo")
        }
    }

    private var previewArea: some View {

        Group {

            if let selectedImage {

                RecordCardRenderer(
                    image: selectedImage,
                    metadata: PhotoMetadata(),
                    anchorResult: anchorResult
                )

            } else {

                RoundedRectangle(
                    cornerRadius: 16
                )
                .fill(.gray.opacity(0.15))
                .frame(height: 300)
                .overlay {

                    Text("Preview")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var templateSection: some View {

        VStack(alignment: .leading) {

            Text("Template")
                .font(.headline)

            Text(
                settingsService.selectedTemplate?.name
                ?? "Classic White"
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    private var photoPicker: some View {

        PhotosPicker(
            selection: $selectedItem,
            matching: .images
        ) {

            Label(
                "Select Photo",
                systemImage: "photo"
            )
        }
        .onChange(of: selectedItem) { _, _ in

            Task {
                await loadImage()
            }
        }
    }

    private var generateButton: some View {

        Button("Generate") {

            guard
                let anchor = settingsService.anchors.first
            else {
                return
            }

            anchorResult =
                anchorEngine.build(
                    from: anchor
                )
        }
        .buttonStyle(.borderedProminent)
    }

    private func loadImage() async {

        guard
            let data = try? await selectedItem?
                .loadTransferable(
                    type: Data.self
                ),
            let nsImage = NSImage(data: data)
        else {
            return
        }

        selectedImage = Image(
            nsImage: nsImage
        )
    }
}
