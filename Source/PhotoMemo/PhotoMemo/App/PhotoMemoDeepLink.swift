import Foundation

enum PhotoMemoDeepLink: Equatable {

    case share

    case processing(jobID: UUID)

    init?(
        url: URL
    ) {

        guard
            let scheme = url.scheme?
                .lowercased(),
            [
                "memomark",
                "photomemo",
            ]
            .contains(scheme)
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

        case "processing":
            let components = url.pathComponents
            guard
                let rawJobID = components.dropFirst().first,
                let jobID = UUID(uuidString: rawJobID)
            else {
                return nil
            }
            self = .processing(jobID: jobID)

        default:
            return nil
        }
    }

    var url: URL {

        switch self {

        case .share:
            return URL(
                string: "memomark://share"
            )!

        case .processing(let jobID):
            return URL(
                string: "memomark://processing/\(jobID.uuidString)"
            )!
        }
    }
}

extension Notification.Name {

    static let photoMemoNotificationOpened = Notification.Name(
        "PhotoMemo.NotificationOpened"
    )
}

enum PhotoMemoNotificationUserInfo {

    static let deepLinkURL = "photoMemo.deepLinkURL"
}
