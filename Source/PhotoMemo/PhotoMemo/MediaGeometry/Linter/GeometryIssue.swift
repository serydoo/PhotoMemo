import Foundation

enum GeometryIssueSeverity:
    String,
    Codable,
    Hashable,
    Sendable {

    case error
    case warning
}

enum GeometryIssueCode:
    String,
    Codable,
    Hashable,
    Sendable {

    case invalidRawPixelSize
    case invalidDisplaySize
    case invalidCanvas
    case photoFrameOutsideCanvas
    case footerOutsideCanvas
    case photoFrameDisplaySizeMismatch
    case footerWidthMismatch
}

struct GeometryIssue:
    Codable,
    Equatable,
    Hashable,
    Sendable {

    let severity: GeometryIssueSeverity
    let code: GeometryIssueCode
    let message: String
    let location: String?
}
