import Foundation

enum MemoryCardModuleID:
    String,
    CaseIterable,
    Identifiable,
    Codable,
    Hashable {

    case subjectNickname
    case smartTime
    case captureDate
    case captureTime
    case cameraMaker
    case cameraModel
    case lensModel
    case focalLength
    case aperture
    case shutterSpeed
    case iso
    case exposureBias
    case meteringMode
    case flash
    case whiteBalance
    case captureSummary
    case location
    case altitude
    case imageSize
    case orientation
    case fileFormat
    case custom

    var id: String {
        rawValue
    }

    var title: String {
        title(for: MemoMarkLanguage.interfaceStored)
    }

    func title(
        for language: MemoMarkLanguage
    ) -> String {
        language.localized(
            key: titleLocalizationKey,
            fallback: fallbackTitle(for: language)
        )
    }

    var systemImage: String {
        switch self {
        case .subjectNickname:
            return "person.fill"
        case .smartTime:
            return "calendar.badge.clock"
        case .captureDate:
            return "calendar"
        case .captureTime:
            return "clock"
        case .cameraMaker:
            return "apple.logo"
        case .cameraModel:
            return "camera.fill"
        case .lensModel:
            return "camera.macro"
        case .focalLength:
            return "scope"
        case .aperture:
            return "camera.aperture"
        case .shutterSpeed:
            return "timer"
        case .iso:
            return "dial.low"
        case .exposureBias:
            return "plusminus"
        case .meteringMode:
            return "camera.metering.center.weighted"
        case .flash:
            return "bolt.fill"
        case .whiteBalance:
            return "sun.max"
        case .captureSummary:
            return "camera.metering.center.weighted"
        case .location:
            return "location.fill"
        case .altitude:
            return "mountain.2.fill"
        case .imageSize:
            return "rectangle.inset.filled"
        case .orientation:
            return "rectangle.rotate"
        case .fileFormat:
            return "doc.fill"
        case .custom:
            return "plus.circle"
        }
    }

    var token: String {
        switch self {
        case .subjectNickname:
            return "{{subject_nickname}}"
        case .smartTime:
            return "{{age_result}}"
        case .captureDate:
            return "{{capture_date}}"
        case .captureTime:
            return "{{capture_time}}"
        case .cameraMaker:
            return "{{camera_make}}"
        case .cameraModel:
            return "{{camera_model}}"
        case .lensModel:
            return "{{lens_model}}"
        case .focalLength:
            return "{{focal_length}}"
        case .aperture:
            return "{{aperture}}"
        case .shutterSpeed:
            return "{{shutter_speed}}"
        case .iso:
            return "{{iso}}"
        case .exposureBias:
            return "{{exposure_bias}}"
        case .meteringMode:
            return "{{metering_mode}}"
        case .flash:
            return "{{flash}}"
        case .whiteBalance:
            return "{{white_balance}}"
        case .captureSummary:
            return "{{capture_parameters_summary}}"
        case .location:
            return "{{location}}"
        case .altitude:
            return "{{altitude}}"
        case .imageSize:
            return "{{image_size}}"
        case .orientation:
            return "{{orientation}}"
        case .fileFormat:
            return "{{file_format}}"
        case .custom:
            return "{{custom}}"
        }
    }

    var rendererToken: String {
        switch self {
        case .subjectNickname:
            return "{{subject_nickname}}"
        case .smartTime:
            return "{{memory_summary}}"
        case .captureDate:
            return "{{capture_date_short}}"
        case .captureTime:
            return "{{capture_time_short}}"
        case .cameraMaker:
            return "{{brand}}"
        case .cameraModel:
            return "{{model}}"
        case .lensModel:
            return "{{lens}}"
        case .focalLength:
            return "{{focal_length}}"
        case .aperture:
            return "{{aperture}}"
        case .shutterSpeed:
            return "{{shutter}}"
        case .iso:
            return "{{iso}}"
        case .captureSummary:
            return "{{camera_summary}}"
        case .location:
            return "{{location_display}}"
        case .altitude:
            return "{{altitude}}"
        case .imageSize:
            return "{{width}} × {{height}}"
        case .orientation:
            return "{{orientation}}"
        case .fileFormat:
            return "{{file_format}}"
        case .exposureBias,
             .meteringMode,
             .flash,
             .whiteBalance,
             .custom:
            return token
        }
    }

    var legacyTokens: Set<String> {
        [token, rendererToken, centerToken]
    }

    var isProductionBacked: Bool {
        switch self {
        case .exposureBias,
             .meteringMode,
             .flash,
             .whiteBalance,
             .fileFormat:
            return false
        default:
            return true
        }
    }

    var centerToken: String {
        self == .smartTime
            ? "{{smart_time_result}}"
            : token
    }

    var previewValue: String {
        previewValue(for: .interfaceStored)
    }

    func previewValue(
        for language: MemoMarkLanguage
    ) -> String {
        switch self {
        case .subjectNickname:
            return language == .simplifiedChinese ? "小宝" : "Sample"
        case .smartTime:
            return language == .simplifiedChinese
                ? "1岁2个月18天"
                : "1 year 2 months 18 days"
        case .captureDate: return "2026.06.01"
        case .captureTime: return "12:00:00"
        case .cameraMaker: return "Apple"
        case .cameraModel: return "iPhone 17 Pro Max"
        case .lensModel: return "iPhone Wide Camera"
        case .focalLength: return "20mm"
        case .aperture: return "f/1.9"
        case .shutterSpeed: return "1/117s"
        case .iso: return "ISO80"
        case .exposureBias: return "0 EV"
        case .meteringMode: return "Pattern"
        case .flash:
            return language == .simplifiedChinese ? "未开启" : "Off"
        case .whiteBalance:
            return language == .simplifiedChinese ? "自动" : "Auto"
        case .captureSummary: return "20mm f/1.9 1/117s ISO80"
        case .location:
            return language == .simplifiedChinese
                ? "示例省 · 示例市"
                : "Sample Province · Sample City"
        case .altitude: return "42m"
        case .imageSize: return "4032 × 3024"
        case .orientation:
            return language == .simplifiedChinese
                ? "横向"
                : "Landscape"
        case .fileFormat: return "HEIC"
        case .custom:
            return language == .simplifiedChinese
                ? "自定义内容"
                : "Custom content"
        }
    }

    private var titleLocalizationKey: String {
        "module.\(rawValue)"
    }

    private func fallbackTitle(
        for language: MemoMarkLanguage
    ) -> String {
        switch (language, self) {
        case (.simplifiedChinese, .subjectNickname): return "对象昵称"
        case (.simplifiedChinese, .smartTime): return "智能结果"
        case (.simplifiedChinese, .captureDate): return "拍摄日期"
        case (.simplifiedChinese, .captureTime): return "拍摄时间"
        case (.simplifiedChinese, .cameraMaker): return "设备厂商"
        case (.simplifiedChinese, .cameraModel): return "设备型号"
        case (.simplifiedChinese, .lensModel): return "镜头型号"
        case (.simplifiedChinese, .focalLength): return "焦距"
        case (.simplifiedChinese, .aperture): return "光圈"
        case (.simplifiedChinese, .shutterSpeed): return "快门"
        case (.simplifiedChinese, .iso): return "ISO"
        case (.simplifiedChinese, .exposureBias): return "曝光补偿"
        case (.simplifiedChinese, .meteringMode): return "测光模式"
        case (.simplifiedChinese, .flash): return "闪光灯"
        case (.simplifiedChinese, .whiteBalance): return "白平衡"
        case (.simplifiedChinese, .captureSummary): return "拍摄参数汇总"
        case (.simplifiedChinese, .location): return "位置"
        case (.simplifiedChinese, .altitude): return "海拔"
        case (.simplifiedChinese, .imageSize): return "图片尺寸"
        case (.simplifiedChinese, .orientation): return "方向"
        case (.simplifiedChinese, .fileFormat): return "文件格式"
        case (.simplifiedChinese, .custom): return "自定义"
        case (.english, .subjectNickname): return "Subject nickname"
        case (.english, .smartTime): return "Memory time"
        case (.english, .captureDate): return "Capture date"
        case (.english, .captureTime): return "Capture time"
        case (.english, .cameraMaker): return "Camera maker"
        case (.english, .cameraModel): return "Camera model"
        case (.english, .lensModel): return "Lens model"
        case (.english, .focalLength): return "Focal length"
        case (.english, .aperture): return "Aperture"
        case (.english, .shutterSpeed): return "Shutter speed"
        case (.english, .iso): return "ISO"
        case (.english, .exposureBias): return "Exposure bias"
        case (.english, .meteringMode): return "Metering mode"
        case (.english, .flash): return "Flash"
        case (.english, .whiteBalance): return "White balance"
        case (.english, .captureSummary): return "Capture summary"
        case (.english, .location): return "Location"
        case (.english, .altitude): return "Altitude"
        case (.english, .imageSize): return "Image size"
        case (.english, .orientation): return "Orientation"
        case (.english, .fileFormat): return "File format"
        case (.english, .custom): return "Custom"
        }
    }
}

enum MemoryCardTemplateTokenCatalog {

    static func module(
        matching expression: String
    ) -> MemoryCardModuleID? {
        MemoryCardModuleID.allCases.first {
            $0.legacyTokens.contains(expression)
        }
    }

    static func title(
        for expression: String,
        language: MemoMarkLanguage
    ) -> String? {
        if let module = module(matching: expression) {
            return module.title(for: language)
        }

        guard let tokenName = tokenName(from: expression) else {
            return nil
        }
        let missing = "__MEMOMARK_MISSING_VARIABLE_TITLE__"
        let localized = language.localized(
            key: "variable.\(tokenName)",
            fallback: missing
        )
        return localized == missing ? nil : localized
    }

    static func tokenName(
        from expression: String
    ) -> String? {
        guard expression.hasPrefix("{{"),
              expression.hasSuffix("}}"),
              expression.count > 4,
              !expression.dropFirst(2).dropLast(2).contains("{")
        else {
            return nil
        }
        return String(expression.dropFirst(2).dropLast(2))
    }
}
