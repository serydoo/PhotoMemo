import SwiftUI
import AppKit

struct MainView: View {

    @State private var selectedPhoto: SelectedPhoto?

    var body: some View {

        NavigationSplitView {

            sidebar

        } detail: {

            detail
        }
    }
}

// MARK: - Sidebar
private extension MainView {

    var sidebar: some View {

        VStack(alignment: .leading, spacing: 20) {

            Text("PhotoMemo")
                .font(.largeTitle)

            PhotoImporterView { photo in

                print("==========")
                print(photo.metadata)

                selectedPhoto = photo
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 260)
    }
}

// MARK: - Detail
private extension MainView {

    @ViewBuilder
    var detail: some View {

        if let photo = selectedPhoto {

            ScrollView {

                VStack(spacing: 0) {

                    // 图片区域
                    RecordCardRenderer(
                        image: Image(nsImage: photo.image),
                        metadata: photo.metadata,
                        anchorResult: AnchorResult(
                            title: "汪小宝成长记录",
                            primaryText: "记录于 \(photo.metadata.locationName ?? "未知地点")",
                            secondaryText: "快乐长大 ❤️"
                        )
                    )
                    .frame(maxWidth: 900)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }

        } else {

            ContentUnavailableView(
                "No Photo Selected",
                systemImage: "photo"
            )
        }
    }

    func cardView(for photo: SelectedPhoto) -> some View {

        VStack(spacing: 6) {

            Text(photo.metadata.deviceModel.isEmpty ? "未知设备" : photo.metadata.deviceModel)
                .font(.headline)

            Text(photo.metadata.captureDate?.description ?? "无时间")
                .font(.subheadline)

            Text(photo.metadata.locationName ?? "未知地点")
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            Color(red: 244/255,
                  green: 243/255,
                  blue: 243/255)
        )
    }
}

#Preview {

    MainView()
}
