#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1OutputPageSurface: View {

    @Binding
    var outputTarget: V1IOSOutputTarget

    let availableAlbums: [PhotoAlbumOption]

    @Binding
    var selectedExistingAlbumIdentifier: String

    @Binding
    var newAlbumName: String

    let isLoadingAlbums: Bool
    let albumStatusMessage: String

    @Binding
    var usesCustomMemoryWriteText: Bool

    @Binding
    var customMemoryWriteText: String

    let resolvedMemoryWriteText: String
    let onDismissKeyboard: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                V1OutputSection(
                    outputTarget: $outputTarget,
                    availableAlbums: availableAlbums,
                    selectedExistingAlbumIdentifier: $selectedExistingAlbumIdentifier,
                    newAlbumName: $newAlbumName,
                    isLoadingAlbums: isLoadingAlbums,
                    albumStatusMessage: albumStatusMessage
                )

                V1MemoryWriteSection(
                    usesCustomMemoryWriteText: $usesCustomMemoryWriteText,
                    customMemoryWriteText: $customMemoryWriteText,
                    resolvedMemoryWriteText: resolvedMemoryWriteText
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 34)
        }
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    onDismissKeyboard()
                }
        )
        .background(
            ConfigurationUI.appBackground
                .ignoresSafeArea()
        )
        .navigationTitle("输出设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct V1OutputSection: View {

    @Binding
    var outputTarget: V1IOSOutputTarget

    let availableAlbums: [PhotoAlbumOption]

    @Binding
    var selectedExistingAlbumIdentifier: String

    @Binding
    var newAlbumName: String

    let isLoadingAlbums: Bool
    let albumStatusMessage: String

    var body: some View {
        V1CardSurface(title: "输出") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("保存位置", selection: $outputTarget) {
                    ForEach(V1IOSOutputTarget.allCases) { target in
                        Text(target.title).tag(target)
                    }
                }
                .pickerStyle(.menu)

                switch outputTarget {
                case .automatic,
                     .applePhotos:
                    EmptyView()

                case .existingAlbum:
                    Picker(
                        "相册",
                        selection: $selectedExistingAlbumIdentifier
                    ) {
                        if availableAlbums.isEmpty {
                            Text("暂无可用相册").tag("")
                        } else {
                            ForEach(availableAlbums) { album in
                                Text(album.title).tag(album.id)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(availableAlbums.isEmpty)

                case .newAlbum:
                    TextField("相册名称", text: $newAlbumName)
                        .textFieldStyle(.roundedBorder)
                }

                Text(outputTarget.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if isLoadingAlbums {
                    Label("正在读取相册", systemImage: "photo.on.rectangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if !albumStatusMessage.isEmpty {
                    Text(albumStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct V1MemoryWriteSection: View {

    @Binding
    var usesCustomMemoryWriteText: Bool

    @Binding
    var customMemoryWriteText: String

    let resolvedMemoryWriteText: String

    var body: some View {
        let presentation = MemoryWriteOptionPresenter.presentation(
            usesCustomText: usesCustomMemoryWriteText,
            resolvedText: resolvedMemoryWriteText
        )

        V1CardSurface(title: "智能模块") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $usesCustomMemoryWriteText) {
                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {
                        Text(presentation.toggleTitle)
                            .font(.subheadline.weight(.semibold))

                        Text(presentation.toggleDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text(presentation.fallbackNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if usesCustomMemoryWriteText {
                    TextField(
                        presentation.inputPlaceholder,
                        text: $customMemoryWriteText,
                        axis: .vertical
                    )
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(presentation.resolvedTitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(presentation.resolvedDescription)
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
    }
}

#endif
