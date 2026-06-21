import Foundation

enum PhotoMemoDeepLink: Equatable {

    case share

    init?(
        url: URL
    ) {

        guard
            let scheme = url.scheme?
                .lowercased(),
            scheme == "photomemo"
        else {
            return nil
        }

        let host =
            url.host?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()

        let path =
            url.path
            .trimmingCharacters(
                in: CharacterSet(
                    charactersIn: "/"
                )
            )
            .lowercased()

        switch host ?? path {
        case "share":
            self = .share

        default:
            return nil
        }
    }

    var url: URL {

        switch self {

        case .share:
            return URL(
                string: "photomemo://share"
            )!
        }
    }
}
