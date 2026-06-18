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

    static let captureDateLine = TemplateItem(
        type: .variable,
        name: "Capture Date Line",
        value: "记录于{{capture_date_display}}"
    )

    static let captureDateCompact = TemplateItem(
        type: .variable,
        name: "Capture Date Compact",
        value: "{{year}}.{{month}}.{{day}}"
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

    static let cameraSummary = TemplateItem(
        type: .variable,
        name: "Camera Summary",
        value: "{{camera_summary}}"
    )

    static let deviceCameraLine = TemplateItem(
        type: .variable,
        name: "Device Camera Line",
        value: "{{model}} · {{camera_summary}}"
    )

    static let gearLine = TemplateItem(
        type: .variable,
        name: "Gear Line",
        value: "{{model}} · {{lens}}"
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
        name: "时间点名称",
        value: "{{anchor_title}}"
    )

    static let anchorPrimary = TemplateItem(
        type: .variable,
        name: "通用结果",
        value: "{{anchor_primary}}"
    )

    static let anchorSmartText = TemplateItem(
        type: .variable,
        name: "智能结果",
        value: "{{anchor_smart_text}}"
    )

    static let anchorAgeText = TemplateItem(
        type: .variable,
        name: "年岁",
        value: "{{anchor_age_text}}"
    )

    static let anchorDurationText = TemplateItem(
        type: .variable,
        name: "纪念时长",
        value: "{{anchor_duration_text}}"
    )

    static let anchorTotalDaysText = TemplateItem(
        type: .variable,
        name: "天数值",
        value: "{{anchor_total_days_text}}"
    )

    static let anchorElapsedText = TemplateItem(
        type: .variable,
        name: "已过天数",
        value: "{{anchor_elapsed_text}}"
    )

    static let anchorCountdownText = TemplateItem(
        type: .variable,
        name: "倒计时",
        value: "{{anchor_countdown_text}}"
    )

    static let anchorDayIndexText = TemplateItem(
        type: .variable,
        name: "第几天",
        value: "{{anchor_day_index_text}}"
    )

    static let anchorWeekText = TemplateItem(
        type: .variable,
        name: "周数",
        value: "{{anchor_week_text}}"
    )

    static let anchorMonthAgeText = TemplateItem(
        type: .variable,
        name: "月龄",
        value: "{{anchor_month_age_text}}"
    )

    static let anchorMilestoneText = TemplateItem(
        type: .variable,
        name: "里程碑",
        value: "{{anchor_milestone_text}}"
    )

    static let anchorAgeSentence = TemplateItem(
        type: .variable,
        name: "成长纪念句",
        value: "今天{{anchor_age_text}}"
    )

    static let anchorDurationSentence = TemplateItem(
        type: .variable,
        name: "纪念时长句",
        value: "已经{{anchor_duration_text}}"
    )

    static let anchorCountdownSentence = TemplateItem(
        type: .variable,
        name: "倒计时句",
        value: "{{anchor_countdown_text}}"
    )

    static let anchorSecondary = TemplateItem(
        type: .variable,
        name: "锚点日期",
        value: "{{anchor_secondary}}"
    )

    static let memorySummary = TemplateItem(
        type: .variable,
        name: "Memory Summary",
        value: "{{memory_summary}}"
    )

    // MARK: - Badge

    static let badge = TemplateItem(
        type: .badge,
        name: "Badge",
        value: "badge"
    )
}
