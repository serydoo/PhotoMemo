//
//  TemplateVariable.swift
//  PhotoMemo
//
//  Created by 汪瑞 on 2026/6/17.
//


import Foundation

struct TemplateVariable: Identifiable, Hashable {

    let id: UUID

    let category: TemplateVariableCategory

    let title: String

    let token: String

    init(
        id: UUID = UUID(),
        category: TemplateVariableCategory,
        title: String,
        token: String
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.token = token
    }
}

extension TemplateVariable {

    static func allToken(
        for key: String
    ) -> String {

        token(for: key)
    }

    private static func token(
        for key: String
    ) -> String {

        "{{\(key)}}"
    }

    private static func recognized(
        _ title: String,
        key: String
    ) -> TemplateVariable {

        TemplateVariable(
            category: .recognized,
            title: title,
            token: token(for: key)
        )
    }

    private static func intelligent(
        _ title: String,
        key: String
    ) -> TemplateVariable {

        TemplateVariable(
            category: .intelligent,
            title: title,
            token: token(for: key)
        )
    }

    private static func user(
        _ title: String,
        key: String
    ) -> TemplateVariable {

        TemplateVariable(
            category: .user,
            title: title,
            token: token(for: key)
        )
    }

    static let all: [TemplateVariable] = [

        // MARK: - User

        user(
            "标题",
            key: MetadataContext.Key.title
        ),

        user(
            "记录者称呼",
            key: MetadataContext.Key.relationshipLabel
        ),

        user(
            "故事",
            key: MetadataContext.Key.story
        ),

        user(
            "标签",
            key: MetadataContext.Key.tags
        ),

        // MARK: - Device

        recognized(
            "品牌",
            key: MetadataContext.Key.brand
        ),

        recognized(
            "型号",
            key: MetadataContext.Key.model
        ),

        recognized(
            "镜头",
            key: MetadataContext.Key.lens
        ),

        recognized(
            "镜头品牌",
            key: MetadataContext.Key.lensBrand
        ),

        recognized(
            "参数摘要",
            key: MetadataContext.Key.cameraSummary
        ),

        // MARK: - Camera

        recognized(
            "ISO",
            key: MetadataContext.Key.iso
        ),

        recognized(
            "光圈",
            key: MetadataContext.Key.aperture
        ),

        recognized(
            "快门",
            key: MetadataContext.Key.shutter
        ),

        recognized(
            "焦距",
            key: MetadataContext.Key.focalLength
        ),

        recognized(
            "35mm焦距",
            key: MetadataContext.Key.focalLength35mm
        ),

        // MARK: - Date

        recognized(
            "年份",
            key: MetadataContext.Key.year
        ),

        recognized(
            "月份",
            key: MetadataContext.Key.month
        ),

        recognized(
            "日期",
            key: MetadataContext.Key.day
        ),

        recognized(
            "小时",
            key: MetadataContext.Key.hour
        ),

        recognized(
            "分钟",
            key: MetadataContext.Key.minute
        ),

        recognized(
            "秒钟",
            key: MetadataContext.Key.second
        ),

        recognized(
            "星期序号",
            key: MetadataContext.Key.weekday
        ),

        recognized(
            "星期名称",
            key: MetadataContext.Key.weekdayName
        ),

        recognized(
            "完整时间",
            key: MetadataContext.Key.captureDateDisplay
        ),

        recognized(
            "短日期",
            key: MetadataContext.Key.captureDateShort
        ),

        recognized(
            "短时间",
            key: MetadataContext.Key.captureTimeShort
        ),

        recognized(
            "时区",
            key: MetadataContext.Key.captureTimezone
        ),

        // MARK: - Image

        recognized(
            "宽度",
            key: MetadataContext.Key.width
        ),

        recognized(
            "高度",
            key: MetadataContext.Key.height
        ),

        recognized(
            "方向",
            key: MetadataContext.Key.orientation
        ),

        recognized(
            "宽高比",
            key: MetadataContext.Key.aspectRatio
        ),

        recognized(
            "像素总量",
            key: MetadataContext.Key.megapixels
        ),

        // MARK: - Location

        recognized(
            "地点名称",
            key: MetadataContext.Key.location
        ),

        recognized(
            "地点显示",
            key: MetadataContext.Key.locationDisplay
        ),

        recognized(
            "国家",
            key: MetadataContext.Key.country
        ),

        recognized(
            "省份",
            key: MetadataContext.Key.province
        ),

        recognized(
            "城市",
            key: MetadataContext.Key.city
        ),

        recognized(
            "区县",
            key: MetadataContext.Key.district
        ),

        recognized(
            "纬度",
            key: MetadataContext.Key.latitude
        ),

        recognized(
            "经度",
            key: MetadataContext.Key.longitude
        ),

        recognized(
            "海拔",
            key: MetadataContext.Key.altitude
        ),

        // MARK: - Memory

        intelligent(
            "已过天数（数字）",
            key: MetadataContext.Key.daysSince
        ),

        intelligent(
            "已过年数（数字）",
            key: MetadataContext.Key.yearsSince
        ),

        intelligent(
            "已过月数（数字）",
            key: MetadataContext.Key.monthsSince
        ),

        intelligent(
            "已过周数（数字）",
            key: MetadataContext.Key.weeksSince
        ),

        intelligent(
            "宝宝年龄",
            key: MetadataContext.Key.babyAge
        ),

        intelligent(
            "记忆摘要",
            key: MetadataContext.Key.memorySummary
        )
    ]
}
