#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct V1MemorySourceDisclosureState: Hashable {

    private(set) var selectedSubjectID: UUID?
    private(set) var isExpanded: Bool

    init(
        selectedSubjectID: UUID? = nil,
        isExpanded: Bool = true
    ) {
        self.selectedSubjectID = selectedSubjectID
        self.isExpanded = isExpanded
    }

    mutating func setExpanded(_ isExpanded: Bool) {
        self.isExpanded = isExpanded
    }

    mutating func synchronize(
        selectedSubjectID: UUID?
    ) {
        guard self.selectedSubjectID != selectedSubjectID else {
            return
        }

        guard self.selectedSubjectID != nil else {
            self.selectedSubjectID = selectedSubjectID
            return
        }

        self.selectedSubjectID = selectedSubjectID
        isExpanded = true
    }
}

struct V1MemoryExpressionDisclosureState: Hashable {

    private(set) var isExpanded: Bool

    init(isExpanded: Bool = true) {
        self.isExpanded = isExpanded
    }

    mutating func setExpanded(_ isExpanded: Bool) {
        self.isExpanded = isExpanded
    }
}

/// Presentation-only disclosure preferences for the Configuration Center.
/// These values are intentionally separate from configuration data and are
/// stored only so the editor can reopen in the user's preferred density.
struct V1ConfigurationDisclosureState: Hashable {

    enum Section: String, CaseIterable {
        case memorySource
        case memoryExpression
        case presentationStyle
        case cardLayout
        case photoDescription
        case outputDestination
    }

    enum StorageKey {
        static let memorySource =
            "photomemo.v1.configurationCenter.memorySourceExpanded"
        static let memoryExpression =
            "photomemo.v1.configurationCenter.memoryExpressionExpanded"
        static let presentationStyle =
            "photomemo.v1.configurationCenter.presentationStyleExpanded"
        static let cardLayout =
            "photomemo.v1.configurationCenter.cardLayoutExpanded"
        static let photoDescription =
            "photomemo.v1.configurationCenter.photoDescriptionExpanded"
        static let outputDestination =
            "photomemo.v1.configurationCenter.outputDestinationExpanded"
    }

    private(set) var memorySourceDisclosureState:
        V1MemorySourceDisclosureState
    private(set) var memoryExpressionDisclosureState:
        V1MemoryExpressionDisclosureState
    private(set) var presentationStyleIsExpanded: Bool
    private(set) var cardLayoutIsExpanded: Bool
    private(set) var photoDescriptionIsExpanded: Bool
    private(set) var outputDestinationIsExpanded: Bool

    init(
        defaults: UserDefaults = .standard
    ) {
        memorySourceDisclosureState = V1MemorySourceDisclosureState(
            isExpanded: Self.value(
                forKey: StorageKey.memorySource,
                defaults: defaults
            )
        )
        memoryExpressionDisclosureState =
            V1MemoryExpressionDisclosureState(
                isExpanded: Self.value(
                    forKey: StorageKey.memoryExpression,
                    defaults: defaults
                )
            )
        presentationStyleIsExpanded = Self.value(
            forKey: StorageKey.presentationStyle,
            defaults: defaults
        )
        cardLayoutIsExpanded = Self.value(
            forKey: StorageKey.cardLayout,
            defaults: defaults
        )
        photoDescriptionIsExpanded = Self.value(
            forKey: StorageKey.photoDescription,
            defaults: defaults
        )
        outputDestinationIsExpanded = Self.value(
            forKey: StorageKey.outputDestination,
            defaults: defaults
        )
    }

    mutating func setExpanded(
        _ isExpanded: Bool,
        for section: Section,
        defaults: UserDefaults = .standard
    ) {
        switch section {
        case .memorySource:
            memorySourceDisclosureState.setExpanded(isExpanded)
        case .memoryExpression:
            memoryExpressionDisclosureState.setExpanded(isExpanded)
        case .presentationStyle:
            presentationStyleIsExpanded = isExpanded
        case .cardLayout:
            cardLayoutIsExpanded = isExpanded
        case .photoDescription:
            photoDescriptionIsExpanded = isExpanded
        case .outputDestination:
            outputDestinationIsExpanded = isExpanded
        }

        defaults.set(
            isExpanded,
            forKey: Self.storageKey(for: section)
        )
    }

    func isExpanded(for section: Section) -> Bool {
        switch section {
        case .memorySource:
            memorySourceDisclosureState.isExpanded
        case .memoryExpression:
            memoryExpressionDisclosureState.isExpanded
        case .presentationStyle:
            presentationStyleIsExpanded
        case .cardLayout:
            cardLayoutIsExpanded
        case .photoDescription:
            photoDescriptionIsExpanded
        case .outputDestination:
            outputDestinationIsExpanded
        }
    }

    mutating func synchronizeSelectedSubject(
        selectedSubjectID: UUID?,
        defaults: UserDefaults = .standard
    ) {
        memorySourceDisclosureState.synchronize(
            selectedSubjectID: selectedSubjectID
        )
        defaults.set(
            memorySourceDisclosureState.isExpanded,
            forKey: StorageKey.memorySource
        )
    }

    private static func value(
        forKey key: String,
        defaults: UserDefaults
    ) -> Bool {
        guard defaults.object(forKey: key) != nil else {
            return true
        }
        return defaults.bool(forKey: key)
    }

    private static func storageKey(
        for section: Section
    ) -> String {
        switch section {
        case .memorySource:
            StorageKey.memorySource
        case .memoryExpression:
            StorageKey.memoryExpression
        case .presentationStyle:
            StorageKey.presentationStyle
        case .cardLayout:
            StorageKey.cardLayout
        case .photoDescription:
            StorageKey.photoDescription
        case .outputDestination:
            StorageKey.outputDestination
        }
    }
}
#endif
