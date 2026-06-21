import Foundation

enum PhotoFileNameResolver {

    private nonisolated static let
        placeholderPrefixes = [
            "photo library",
            "photomemo import"
        ]

    nonisolated static func sanitizedOriginalFileName(
        _ candidate: String?
    ) -> String? {

        guard
            let candidate,
            !candidate
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
        else {
            return nil
        }

        let normalizedFileName =
            URL(fileURLWithPath: candidate)
            .lastPathComponent
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !normalizedFileName.isEmpty else {
            return nil
        }

        let baseName =
            URL(fileURLWithPath: normalizedFileName)
            .deletingPathExtension()
            .lastPathComponent
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard
            !baseName.isEmpty,
            !isSystemPhotoLibraryPlaceholder(
                baseName
            )
        else {
            return nil
        }

        return normalizedFileName
    }

    nonisolated static func outputBaseName(
        preferredOriginalFileName: String?,
        assetOriginalFileName: String? = nil,
        captureDate: Date? = nil,
        timeZone: TimeZone? = nil,
        fallbackBaseName: String = "PhotoMemo"
    ) -> String {

        if let resolvedFileName =
            sanitizedOriginalFileName(
                preferredOriginalFileName
            )
            ?? sanitizedOriginalFileName(
                assetOriginalFileName
            ) {

            let baseName =
                URL(fileURLWithPath: resolvedFileName)
                .deletingPathExtension()
                .lastPathComponent
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            if !baseName.isEmpty {
                return baseName
            }
        }

        if let captureDate {
            return timestampFallbackBaseName(
                from: captureDate,
                timeZone: timeZone
            )
        }

        let trimmedFallbackBaseName =
            fallbackBaseName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmedFallbackBaseName
            .isEmpty
            ? "PhotoMemo"
            : trimmedFallbackBaseName
    }

    nonisolated static func timestampFallbackBaseName(
        from date: Date,
        timeZone: TimeZone? = nil
    ) -> String {

        let formatter = DateFormatter()
        formatter.calendar =
            Calendar(identifier: .gregorian)
        formatter.locale =
            Locale(identifier: "en_US_POSIX")
        formatter.timeZone =
            timeZone
            ?? TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd_HHmmss"

        return "IMG_\(formatter.string(from: date))"
    }

    private nonisolated static func isSystemPhotoLibraryPlaceholder(
        _ baseName: String
    ) -> Bool {

        let lowercaseBaseName =
            baseName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()

        guard !lowercaseBaseName.isEmpty else {
            return false
        }

        return placeholderPrefixes.contains {
            isPlaceholderVariant(
                lowercaseBaseName,
                prefix: $0
            )
        }
    }

    private nonisolated static func isPlaceholderVariant(
        _ normalizedBaseName: String,
        prefix: String
    ) -> Bool {

        if normalizedBaseName == prefix {
            return true
        }

        guard
            normalizedBaseName.hasPrefix(
                prefix + " "
            )
        else {
            return false
        }

        let suffix =
            normalizedBaseName.dropFirst(
                prefix.count + 1
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !suffix.isEmpty,
           suffix.allSatisfy(\.isNumber) {
            return true
        }

        guard
            suffix.first == "(",
            suffix.last == ")"
        else {
            return false
        }

        let wrappedValue =
            suffix
            .dropFirst()
            .dropLast()
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return !wrappedValue.isEmpty
            && wrappedValue.allSatisfy(\.isNumber)
    }
}
