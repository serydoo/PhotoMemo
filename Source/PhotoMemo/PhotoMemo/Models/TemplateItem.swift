import Foundation

struct TemplateItem: Identifiable, Codable, Hashable {

    let id: UUID

    var type: TemplateItemType

    var name: String

    var value: String

    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        type: TemplateItemType,
        name: String,
        value: String,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.value = value
        self.isEnabled = isEnabled
    }
}

extension TemplateItem {

    // MARK: - User

    static let title = TemplateItem(
        type: .variable,
        name: "Title",
        value: "{{title}}"
    )

    static let story = TemplateItem(
        type: .variable,
        name: "Story",
        value: "{{story}}"
    )

    static let tags = TemplateItem(
        type: .variable,
        name: "Tags",
        value: "{{tags}}"
    )

    // MARK: - Device

    static let brand = TemplateItem(
        type: .variable,
        name: "Brand",
        value: "{{brand}}"
    )

    static let model = TemplateItem(
        type: .variable,
        name: "Model",
        value: "{{model}}"
    )

    static let lens = TemplateItem(
        type: .variable,
        name: "Lens",
        value: "{{lens}}"
    )

    // MARK: - Camera

    static let iso = TemplateItem(
        type: .variable,
        name: "ISO",
        value: "{{iso}}"
    )

    static let aperture = TemplateItem(
        type: .variable,
        name: "Aperture",
        value: "{{aperture}}"
    )

    static let shutter = TemplateItem(
        type: .variable,
        name: "Shutter",
        value: "{{shutter}}"
    )

    static let focalLength = TemplateItem(
        type: .variable,
        name: "Focal Length",
        value: "{{focal_length}}"
    )

    static let focalLength35 = TemplateItem(
        type: .variable,
        name: "35mm",
        value: "{{focal_len_in_35mm_film}}"
    )

    // MARK: - Date

    static let year = TemplateItem(
        type: .variable,
        name: "Year",
        value: "{{year}}"
    )

    static let month = TemplateItem(
        type: .variable,
        name: "Month",
        value: "{{month}}"
    )

    static let day = TemplateItem(
        type: .variable,
        name: "Day",
        value: "{{day}}"
    )

    static let hour = TemplateItem(
        type: .variable,
        name: "Hour",
        value: "{{hour}}"
    )

    static let minute = TemplateItem(
        type: .variable,
        name: "Minute",
        value: "{{minute}}"
    )

    static let second = TemplateItem(
        type: .variable,
        name: "Second",
        value: "{{second}}"
    )

    static let weekday = TemplateItem(
        type: .variable,
        name: "Weekday",
        value: "{{weekday_name}}"
    )

    static let dateTime = TemplateItem(
        type: .variable,
        name: "DateTime",
        value: "{{year}}-{{month}}-{{day}} {{hour}}:{{minute}}"
    )

    // MARK: - GPS

    static let latitude = TemplateItem(
        type: .variable,
        name: "Latitude",
        value: "{{latitude}}"
    )

    static let longitude = TemplateItem(
        type: .variable,
        name: "Longitude",
        value: "{{longitude}}"
    )

    static let altitude = TemplateItem(
        type: .variable,
        name: "Altitude",
        value: "{{altitude}}"
    )

    static let location = TemplateItem(
        type: .variable,
        name: "Location",
        value: "{{location}}"
    )

    static let city = TemplateItem(
        type: .variable,
        name: "City",
        value: "{{city}}"
    )

    static let province = TemplateItem(
        type: .variable,
        name: "Province",
        value: "{{province}}"
    )

    static let country = TemplateItem(
        type: .variable,
        name: "Country",
        value: "{{country}}"
    )

    // MARK: - Anchor

    static let anchorTitle = TemplateItem(
        type: .variable,
        name: "Anchor Title",
        value: "{{anchor_title}}"
    )

    static let anchorPrimary = TemplateItem(
        type: .variable,
        name: "Anchor Primary",
        value: "{{anchor_primary}}"
    )

    static let anchorSecondary = TemplateItem(
        type: .variable,
        name: "Anchor Secondary",
        value: "{{anchor_secondary}}"
    )

    // MARK: - Badge

    static let badge = TemplateItem(
        type: .badge,
        name: "Badge",
        value: "badge"
    )
}
