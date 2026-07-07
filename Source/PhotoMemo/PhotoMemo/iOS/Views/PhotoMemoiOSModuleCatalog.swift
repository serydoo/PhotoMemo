#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct IOSInsertedModule:
    Identifiable,
    Hashable {

    let id: UUID
    let title: String
    let value: String
    let systemImage: String
    let expressionConfiguration: ExpressionModuleConfiguration?

    init(
        id: UUID = UUID(),
        title: String,
        value: String,
        systemImage: String,
        expressionConfiguration: ExpressionModuleConfiguration? = nil
    ) {
        self.id = id
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.expressionConfiguration = expressionConfiguration
    }
}

enum IOSInsertableModule:
    String,
    CaseIterable,
    Identifiable {

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
        switch self {
        case .subjectNickname:
            return "对象昵称"
        case .smartTime:
            return "智能结果"
        case .captureDate:
            return "拍摄日期"
        case .captureTime:
            return "拍摄时间"
        case .cameraMaker:
            return "设备厂商"
        case .cameraModel:
            return "设备型号"
        case .lensModel:
            return "镜头型号"
        case .focalLength:
            return "焦距"
        case .aperture:
            return "光圈"
        case .shutterSpeed:
            return "快门"
        case .iso:
            return "ISO"
        case .exposureBias:
            return "曝光补偿"
        case .meteringMode:
            return "测光模式"
        case .flash:
            return "闪光灯"
        case .whiteBalance:
            return "白平衡"
        case .captureSummary:
            return "拍摄参数汇总"
        case .location:
            return "位置"
        case .altitude:
            return "海拔"
        case .imageSize:
            return "图片尺寸"
        case .orientation:
            return "方向"
        case .fileFormat:
            return "文件格式"
        case .custom:
            return "自定义"
        }
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
}
#endif
