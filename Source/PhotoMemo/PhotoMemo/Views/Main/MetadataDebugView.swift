//
//  MetadataDebugView.swift
//  PhotoMemo
//
//  Created by 汪瑞 on 2026/6/17.
//


import SwiftUI

struct MetadataFieldComparison:
    Identifiable,
    Hashable {

    let id = UUID()

    let title: String

    let sourceValue: String

    let exportedValue: String

    let isMatch: Bool
}

struct MetadataValidationReport:
    Identifiable,
    Hashable {

    let id = UUID()

    let validatedTargetName: String

    let sourceLabel: String

    let targetLabel: String

    let source: PhotoMetadata

    let exported: PhotoMetadata

    var matchedFieldCount: Int {

        comparisons.filter(\.isMatch).count
    }

    var comparisons: [MetadataFieldComparison] {

        [
            comparison(
                "Capture Date",
                source.captureDate,
                exported.captureDate
            ),
            comparison(
                "Brand",
                source.deviceBrand,
                exported.deviceBrand
            ),
            comparison(
                "Model",
                source.deviceModel,
                exported.deviceModel
            ),
            comparison(
                "Lens",
                source.lensModel,
                exported.lensModel
            ),
            comparison(
                "ISO",
                source.iso,
                exported.iso
            ),
            comparison(
                "Aperture",
                source.aperture,
                exported.aperture
            ),
            comparison(
                "Shutter",
                source.shutterSpeed,
                exported.shutterSpeed
            ),
            comparison(
                "Focal Length",
                source.focalLength,
                exported.focalLength
            ),
            comparison(
                "35mm",
                source.focalLength35mm,
                exported.focalLength35mm
            ),
            comparison(
                "Width",
                source.imageWidth,
                exported.imageWidth
            ),
            comparison(
                "Height",
                source.imageHeight,
                exported.imageHeight
            ),
            comparison(
                "Latitude",
                source.latitude,
                exported.latitude
            ),
            comparison(
                "Longitude",
                source.longitude,
                exported.longitude
            ),
            comparison(
                "Altitude",
                source.altitude,
                exported.altitude
            )
        ]
    }
}

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

            Section("GPS") {

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

struct MetadataValidationDebugView:
    View {

    let report: MetadataValidationReport

    var body: some View {

        List {

            Section("Summary") {

                row(
                    "Validated Target",
                    report.validatedTargetName
                )

                row(
                    "Matched Fields",
                    "\(report.matchedFieldCount)/\(report.comparisons.count)"
                )
            }

            Section("Field Comparison") {

                ForEach(report.comparisons) {
                    comparison in

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        HStack {

                            Text(comparison.title)
                                .font(.subheadline.weight(.medium))

                            Spacer()

                            Label(
                                comparison.isMatch
                                    ? "Matched"
                                    : "Changed",
                                systemImage:
                                    comparison.isMatch
                                    ? "checkmark.circle.fill"
                                    : "exclamationmark.circle.fill"
                            )
                            .font(.caption.weight(.medium))
                            .foregroundStyle(
                                comparison.isMatch
                                    ? Color.green
                                    : Color.orange
                            )
                        }

                        valueRow(
                            report.sourceLabel,
                            comparison.sourceValue
                        )

                        valueRow(
                            report.targetLabel,
                            comparison.exportedValue
                        )
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Raw Metadata") {

                NavigationLink("\(report.sourceLabel) Metadata") {
                    MetadataDebugView(
                        metadata: report.source
                    )
                }

                NavigationLink("\(report.targetLabel) Metadata") {
                    MetadataDebugView(
                        metadata: report.exported
                    )
                }
            }
        }
        .navigationTitle(
            "Metadata Validation"
        )
    }
}

private extension MetadataValidationDebugView {

    @ViewBuilder
    func row(
        _ title: String,
        _ value: String
    ) -> some View {

        HStack {

            Text(title)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder
    func valueRow(
        _ title: String,
        _ value: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 10
        ) {

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 58, alignment: .leading)

            Text(value.isEmpty ? "Empty" : value)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }
}

private extension MetadataValidationReport {

    func comparison(
        _ title: String,
        _ sourceValue: String,
        _ exportedValue: String
    ) -> MetadataFieldComparison {

        let normalizedSource =
            normalized(sourceValue)
        let normalizedExported =
            normalized(exportedValue)

        return MetadataFieldComparison(
            title: title,
            sourceValue: normalizedSource,
            exportedValue: normalizedExported,
            isMatch:
                normalizedSource == normalizedExported
        )
    }

    func comparison(
        _ title: String,
        _ sourceValue: Int?,
        _ exportedValue: Int?
    ) -> MetadataFieldComparison {

        comparison(
            title,
            sourceValue.map(String.init) ?? "",
            exportedValue.map(String.init) ?? ""
        )
    }

    func comparison(
        _ title: String,
        _ sourceValue: Double?,
        _ exportedValue: Double?
    ) -> MetadataFieldComparison {

        comparison(
            title,
            formatted(sourceValue),
            formatted(exportedValue)
        )
    }

    func comparison(
        _ title: String,
        _ sourceValue: Date?,
        _ exportedValue: Date?
    ) -> MetadataFieldComparison {

        comparison(
            title,
            formatted(sourceValue),
            formatted(exportedValue)
        )
    }

    func formatted(
        _ value: Double?
    ) -> String {

        guard let value else {
            return ""
        }

        return String(
            format: "%.6f",
            value
        )
    }

    func formatted(
        _ value: Date?
    ) -> String {

        guard let value else {
            return ""
        }

        let formatter =
            DateFormatter()

        formatter.locale =
            Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(
            from: value
        )
    }

    func normalized(
        _ value: String
    ) -> String {

        value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
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
