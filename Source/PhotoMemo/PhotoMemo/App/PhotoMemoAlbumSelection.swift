import Foundation

enum PhotoMemoAlbumSelection {

    static let automaticIdentifier =
        "__photomemo_auto__"

    static let systemLibraryIdentifier =
        "__photomemo_system__"

    static func normalizedIdentifier(
        _ identifier: String
    ) -> String {

        if identifier.isEmpty
            || identifier == automaticIdentifier {
            return ""
        }

        return identifier
    }
}
