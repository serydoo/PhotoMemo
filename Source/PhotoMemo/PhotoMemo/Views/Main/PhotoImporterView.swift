import SwiftUI
import UniformTypeIdentifiers

struct PhotoImporterView: View {

    let onImport: (SelectedPhoto) -> Void

    @State
    private var showImporter = false

    @State
    private var errorMessage: String?

    private let importService =
        PhotoImportService()

    var body: some View {

        VStack(spacing: 16) {

            Button {

                showImporter = true

            } label: {

                Label(
                    "Select Photo",
                    systemImage: "photo"
                )
            }

            if let errorMessage {

                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes:
                importService.supportedTypes(),
            allowsMultipleSelection: false
        ) { result in

            handle(result)
        }
    }
}

private extension PhotoImporterView {

    func handle(
        _ result: Result<[URL], Error>
    ) {

        do {

            let urls =
                try result.get()

            guard let url = urls.first else {
                return
            }

            guard
                importService.isSupported(url)
            else {

                errorMessage =
                    "Unsupported image format"

                return
            }

            Task {

                let photo =
                    await importService.importPhoto(
                        from: url
                    )

                await MainActor.run {

                    onImport(photo)
                }
            }

            errorMessage = nil

        } catch {

            errorMessage =
                error.localizedDescription
        }
    }
}

#Preview {

    PhotoImporterView { _ in

    }
}
