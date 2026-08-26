import Foundation

enum LocationPresentationMode:
    String,
    Hashable,
    Codable,
    CaseIterable {

    case provinceCity

    case cityDistrict

    case provinceCityDistrict

    case coordinate

    case legacyDisplay
}
