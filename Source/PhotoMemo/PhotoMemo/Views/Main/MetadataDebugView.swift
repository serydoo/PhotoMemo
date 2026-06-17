//
//  MetadataDebugView.swift
//  PhotoMemo
//
//  Created by 汪瑞 on 2026/6/17.
//


import SwiftUI

struct MetadataDebugView: View {

    let metadata: PhotoMetadata

    var body: some View {

        List {

            Section("Device") {

                row(
                    "Brand",
                    metadata.deviceBrand
                )

                row(
                    "Model",
                    metadata.deviceModel
                )

                row(
                    "Lens",
                    metadata.lensModel
                )
            }

            Section("Camera") {

                row(
                    "ISO",
                    metadata.iso
                )

                row(
                    "Aperture",
                    metadata.aperture
                )

                row(
                    "Shutter",
                    metadata.shutterSpeed
                )

                row(
                    "Focal Length",
                    metadata.focalLength
                )

                row(
                    "35mm",
                    metadata.focalLength35mm
                )
            }

            Section("Image") {

                row(
                    "Width",
                    metadata.imageWidth
                        .map(String.init)
                    ?? ""
                )

                row(
                    "Height",
                    metadata.imageHeight
                        .map(String.init)
                    ?? ""
                )
            }

            Section("Location") {

                row(
                    "Latitude",
                    metadata.latitude
                        .map { String($0) }
                    ?? ""
                )

                row(
                    "Longitude",
                    metadata.longitude
                        .map { String($0) }
                    ?? ""
                )

                row(
                    "Altitude",
                    metadata.altitude
                        .map { String($0) }
                    ?? ""
                )

                row(
                    "City",
                    metadata.city ?? ""
                )

                row(
                    "Province",
                    metadata.province ?? ""
                )

                row(
                    "Country",
                    metadata.country ?? ""
                )

                row(
                    "Location",
                    metadata.locationName ?? ""
                )
            }

            Section("Date") {

                row(
                    "Capture Date",
                    captureDateText
                )
            }
        }
        .navigationTitle(
            "Metadata"
        )
    }
}

private extension MetadataDebugView {

    var captureDateText: String {

        guard
            let date =
                metadata.captureDate
        else {
            return ""
        }

        let formatter =
            DateFormatter()

        formatter.dateStyle = .medium

        formatter.timeStyle = .medium

        return formatter.string(
            from: date
        )
    }

    @ViewBuilder
    func row(
        _ title: String,
        _ value: String
    ) -> some View {

        HStack {

            Text(title)

            Spacer()

            Text(value)
                .foregroundStyle(
                    .secondary
                )
                .multilineTextAlignment(
                    .trailing
                )
        }
    }
}

#Preview {

    MetadataDebugView(
        metadata: PhotoMetadata(
            deviceBrand: "Apple",
            deviceModel: "iPhone 17 Pro Max",
            lensModel: "24mm",
            iso: "80",
            aperture: "1.8",
            shutterSpeed: "1/250"
        )
    )
}
