import Foundation

/// Developer-owned public destinations; App Store resolves availability and storefront.
enum MemoMarkAppStoreDestination {
    case review
    case updates

    var url: URL {
        let product = "https://apps.apple.com/app/id6788331801"
        // Both strings are fixed, valid HTTPS URLs, independent of user input.
        return URL(string: self == .review ? product + "?action=write-review" : product)!
    }
}
