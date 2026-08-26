import Foundation

enum PhotoFileNameResolver {

    private nonisolated static let
        placeholderPrefixes = [
            "photo library",
            "memomark import",
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
        fallbackBaseName: String = "MemoMark"
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
            ? "MemoMark"
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

    nonisolated static func outputCopyBaseName(
        from originalBaseName: String,
        index: Int
    ) -> String {

        let trimmedBaseName =
            originalBaseName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let safeBaseName =
            trimmedBaseName.isEmpty
            ? "MemoMark"
            : trimmedBaseName

        return "\(safeBaseName) (\(max(index, 1)))"
    }

    nonisolated static func nextOutputCopyBaseName(
        from proposedBaseName: String,
        exists: (String) -> Bool
    ) -> String {

        let parsed = parsedOutputCopyBaseName(
            proposedBaseName
        )
        let rootBaseName = parsed.root
        var index = parsed.index ?? 1

        while true {
            let candidate =
                outputCopyBaseName(
                    from: rootBaseName,
                    index: index
                )

            if !exists(candidate) {
                return candidate
            }

            index += 1
        }
    }

    nonisolated static func rootOutputBaseName(
        _ proposedBaseName: String
    ) -> String {

        parsedOutputCopyBaseName(
            proposedBaseName
        ).root
    }

    nonisolated static func outputCopyIndex(
        _ proposedBaseName: String
    ) -> Int? {

        parsedOutputCopyBaseName(
            proposedBaseName
        ).index
    }

    nonisolated static func isPhotoKitInternalResourceFileName(
        _ candidate: String?
    ) -> Bool {
        guard let fileName = sanitizedOriginalFileName(
            candidate
        ) else {
            return false
        }
        return URL(fileURLWithPath: fileName)
            .deletingPathExtension()
            .lastPathComponent
            .lowercased() == "fullsizerender"
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

    private nonisolated static func parsedOutputCopyBaseName(
        _ proposedBaseName: String
    ) -> (root: String, index: Int?) {

        let trimmedBaseName =
            proposedBaseName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard
            let openParenIndex =
                trimmedBaseName.lastIndex(of: "("),
            trimmedBaseName.last == ")"
        else {
            return (
                trimmedBaseName.isEmpty ? "MemoMark" : trimmedBaseName,
                nil
            )
        }

        let numberStart =
            trimmedBaseName.index(after: openParenIndex)
        let numberText =
            trimmedBaseName[
                numberStart..<trimmedBaseName.index(before: trimmedBaseName.endIndex)
            ]

        guard
            !numberText.isEmpty,
            numberText.allSatisfy(\.isNumber),
            let index = Int(numberText)
        else {
            return (
                trimmedBaseName.isEmpty ? "MemoMark" : trimmedBaseName,
                nil
            )
        }

        let root =
            String(trimmedBaseName[..<openParenIndex])
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return (
            root.isEmpty ? "MemoMark" : root,
            max(index, 1)
        )
    }
}

actor LivePhotoOutputFilenameSequenceStore {

    private let storageURL: URL
    private let maximumEntryCount: Int
    private var ledger: FilenameSequenceLedger?

    static let shared = LivePhotoOutputFilenameSequenceStore()

    init(
        storageURL: URL =
            MemoMarkSharedContainer.baseDirectoryURL
            .appendingPathComponent(
                "LivePhotoOutputFilenameSequence.v1.json"
            ),
        maximumEntryCount: Int = 512
    ) {
        self.storageURL = storageURL
        self.maximumEntryCount = max(maximumEntryCount, 1)
    }

    func nextOutputBaseName(
        preferredOriginalFileName: String?,
        assetOriginalFileName: String? = nil,
        captureDate: Date? = nil,
        timeZone: TimeZone? = nil
    ) async throws -> String {
        let resolvedBaseName =
            PhotoFileNameResolver.outputBaseName(
                preferredOriginalFileName:
                    preferredOriginalFileName,
                assetOriginalFileName:
                    PhotoFileNameResolver
                    .isPhotoKitInternalResourceFileName(
                        assetOriginalFileName
                    )
                    ? nil
                    : assetOriginalFileName,
                captureDate: captureDate,
                timeZone: timeZone
            )
        return try await nextOutputBaseName(
            from: resolvedBaseName
        )
    }

    func nextOutputBaseName(
        from proposedBaseName: String
    ) async throws -> String {
        let rootBaseName =
            PhotoFileNameResolver.rootOutputBaseName(
                proposedBaseName
            )
        let sequenceKey =
            rootBaseName.lowercased()
        var updatedLedger = try loadLedgerIfNeeded()
        let previousIndex = max(
            updatedLedger.entries[sequenceKey]?.lastIndex ?? 0,
            PhotoFileNameResolver.outputCopyIndex(
                proposedBaseName
            ) ?? 0
        )
        let nextIndex = previousIndex < Int.max
            ? previousIndex + 1
            : Int.max
        updatedLedger.lastAccessOrdinal =
            updatedLedger.lastAccessOrdinal < Int.max
            ? updatedLedger.lastAccessOrdinal + 1
            : Int.max
        updatedLedger.entries[sequenceKey] =
            FilenameSequenceEntry(
                lastIndex: nextIndex,
                lastAccessOrdinal:
                    updatedLedger.lastAccessOrdinal
            )
        updatedLedger.trimToMaximumEntryCount(
            maximumEntryCount
        )
        try persist(updatedLedger)
        ledger = updatedLedger

        return PhotoFileNameResolver.outputCopyBaseName(
            from: rootBaseName,
            index: nextIndex
        )
    }

    private func loadLedgerIfNeeded() throws
    -> FilenameSequenceLedger {

        if let ledger {
            return ledger
        }

        let loadedLedger = try loadLedger()
        ledger = loadedLedger
        return loadedLedger
    }

    private func loadLedger() throws
    -> FilenameSequenceLedger {

        guard FileManager.default.fileExists(
            atPath: storageURL.path
        ) else {
            return FilenameSequenceLedger()
        }
        do {
            let data = try Data(contentsOf: storageURL)
            if let ledger = try? JSONDecoder().decode(
                FilenameSequenceLedger.self,
                from: data
            ) {
                guard ledger.version
                    == FilenameSequenceLedger.currentVersion
                else {
                    throw LivePhotoOutputFilenameSequenceError
                        .invalidData(
                            "Unsupported filename sequence version."
                        )
                }

                var normalizedLedger = ledger
                normalizedLedger.trimToMaximumEntryCount(
                    maximumEntryCount
                )
                return normalizedLedger
            }

            let legacySequences = try JSONDecoder().decode(
                [String: Int].self,
                from: data
            )
            return FilenameSequenceLedger(
                legacySequences: legacySequences,
                maximumEntryCount: maximumEntryCount
            )
        } catch let error as DecodingError {
            throw LivePhotoOutputFilenameSequenceError
                .invalidData(String(describing: error))
        } catch let error as LivePhotoOutputFilenameSequenceError {
            throw error
        } catch {
            throw LivePhotoOutputFilenameSequenceError
                .readFailed(String(describing: error))
        }
    }

    private func persist(
        _ ledger: FilenameSequenceLedger
    ) throws {
        do {
            try FileManager.default.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(ledger)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            throw LivePhotoOutputFilenameSequenceError
                .writeFailed(String(describing: error))
        }
    }
}

private nonisolated struct FilenameSequenceLedger: Codable, Sendable {

    static let currentVersion = 2

    let version: Int
    var lastAccessOrdinal: Int
    var entries: [String: FilenameSequenceEntry]

    init() {
        version = Self.currentVersion
        lastAccessOrdinal = 0
        entries = [:]
    }

    init(
        legacySequences: [String: Int],
        maximumEntryCount: Int
    ) {
        version = Self.currentVersion
        let sortedSequences = legacySequences
            .sorted { lhs, rhs in
                lhs.key.localizedStandardCompare(rhs.key)
                == .orderedAscending
            }
            .suffix(maximumEntryCount)

        entries = Dictionary(
            uniqueKeysWithValues:
                sortedSequences.enumerated().map { offset, sequence in
                    (
                        sequence.key,
                        FilenameSequenceEntry(
                            lastIndex: max(sequence.value, 0),
                            lastAccessOrdinal: offset + 1
                        )
                    )
                }
        )
        lastAccessOrdinal = entries.count
    }

    mutating func trimToMaximumEntryCount(
        _ maximumEntryCount: Int
    ) {
        while entries.count > maximumEntryCount,
              let leastRecentlyUsedKey = entries.min(
                by: { lhs, rhs in
                    if lhs.value.lastAccessOrdinal
                        == rhs.value.lastAccessOrdinal {
                        return lhs.key < rhs.key
                    }
                    return lhs.value.lastAccessOrdinal
                        < rhs.value.lastAccessOrdinal
                }
              )?.key {
            entries.removeValue(forKey: leastRecentlyUsedKey)
        }
    }
}

private nonisolated struct FilenameSequenceEntry: Codable, Sendable {

    let lastIndex: Int
    let lastAccessOrdinal: Int
}

enum LivePhotoOutputFilenameSequenceError:
    LocalizedError,
    Equatable {

    case readFailed(String)
    case invalidData(String)
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .readFailed:
            return "Unable to read the Live Photo filename sequence."
        case .invalidData:
            return "The Live Photo filename sequence is invalid."
        case .writeFailed:
            return "Unable to save the Live Photo filename sequence."
        }
    }
}
