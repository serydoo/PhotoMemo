import SwiftUI
import AppKit
import CoreLocation

struct ContentView: View {

    @State private var metadata: PhotoMetadata?
    @State private var image: NSImage?
    @State private var locationText: String?

    private let geocoder = CLGeocoder()

    var body: some View {

        VStack(spacing: 20) {

            if let image {

                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)

            } else {

                Image(systemName: "photo")
                    .font(.system(size: 60))
            }

            Text("拖入照片")

            if let metadata {

                Text(metadata.fileName)
                    .foregroundStyle(.blue)

                if let captureDate = metadata.captureDate {

                    Text("拍摄时间：\(captureDate)")
                }

                if let cameraModel = metadata.cameraModel {

                    Text("设备：\(cameraModel)")
                }

                if let latitude = metadata.latitude,
                   let longitude = metadata.longitude {

                    Text("纬度：\(latitude)")
                    Text("经度：\(longitude)")
                }

                if let locationText {

                    Text("地点：\(locationText)")
                        .foregroundStyle(.green)
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .onDrop(
            of: ["public.file-url"],
            isTargeted: nil
        ) { providers in

            guard let provider = providers.first else {
                return false
            }

            provider.loadItem(
                forTypeIdentifier: "public.file-url",
                options: nil
            ) { item, _ in

                guard let data = item as? Data,
                      let url = URL(
                        dataRepresentation: data,
                        relativeTo: nil
                      ) else {
                    return
                }

                let info = PhotoMetadata.load(from: url)

                let previewImage = NSImage(contentsOf: url)

                DispatchQueue.main.async {

                    metadata = info
                    image = previewImage
                    locationText = nil
                }

                if let lat = info.latitude,
                   let lon = info.longitude {

                    let location = CLLocation(
                        latitude: lat,
                        longitude: lon
                    )

                    geocoder.reverseGeocodeLocation(location) {
                        placemarks,
                        error in

                        guard let place = placemarks?.first else {
                            return
                        }

                        let address = [
                            place.administrativeArea,
                            place.locality,
                            place.subLocality
                        ]
                        .compactMap { $0 }
                        .joined(separator: " ")

                        DispatchQueue.main.async {

                            locationText = address
                        }
                    }
                }
            }

            return true
        }
    }
}

#Preview {
    ContentView()
}
