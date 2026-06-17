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

    static let all: [TemplateVariable] = [

        // MARK: - User

        TemplateVariable(
            category: .user,
            title: "标题",
            token: "{{title}}"
        ),

        TemplateVariable(
            category: .user,
            title: "故事",
            token: "{{story}}"
        ),

        TemplateVariable(
            category: .user,
            title: "标签",
            token: "{{tags}}"
        ),

        // MARK: - Device

        TemplateVariable(
            category: .recognized,
            title: "品牌",
            token: "{{brand}}"
        ),

        TemplateVariable(
            category: .recognized,
            title: "型号",
            token: "{{model}}"
        ),

        TemplateVariable(
            category: .recognized,
            title: "镜头",
            token: "{{lens}}"
        ),

        // MARK: - Camera

        TemplateVariable(
            category: .recognized,
            title: "ISO",
            token: "{{iso}}"
        ),

        TemplateVariable(
            category: .recognized,
            title: "光圈",
            token: "{{aperture}}"
        ),

        TemplateVariable(
            category: .recognized,
            title: "快门",
            token: "{{shutter}}"
        ),

        TemplateVariable(
            category: .recognized,
            title: "焦距",
            token: "{{focal_length}}"
        ),

        TemplateVariable(
            category: .recognized,
            title: "35mm焦距",
            token: "{{focal_len_in_35mm_film}}"
        ),

        // MARK: - Date

        TemplateVariable(
            category: .recognized,
            title: "年份",
            token: "{{year}}"
        ),

        TemplateVariable(
            category: .recognized,
            title: "月份",
            token: "{{month}}"
        ),

        TemplateVariable(
            category: .recognized,
            title: "日期",
            token: "{{day}}"
        ),

        TemplateVariable(
            category: .recognized,
            title: "小时",
            token: "{{hour}}"
        ),

        TemplateVariable(
            category: .recognized,
            title: "分钟",
            token: "{{minute}}"
        ),

        TemplateVariable(
            category: .recognized,
            title: "秒钟",
            token: "{{second}}"
        ),

        TemplateVariable(
            category: .recognized,
            title: "星期",
            token: "{{weekday_name}}"
        ),

        // MARK: - Image

        TemplateVariable(
            category: .recognized,
            title: "宽度",
            token: "{{width}}"
        ),

        TemplateVariable(
            category: .recognized,
            title: "高度",
            token: "{{height}}"
        ),

        // MARK: - GPS

        TemplateVariable(
            category: .intelligent,
            title: "位置",
            token: "{{location}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "城市",
            token: "{{city}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "省份",
            token: "{{province}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "国家",
            token: "{{country}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "纬度",
            token: "{{latitude}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "经度",
            token: "{{longitude}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "海拔",
            token: "{{altitude}}"
        ),

        // MARK: - Anchor

        TemplateVariable(
            category: .intelligent,
            title: "纪念标题",
            token: "{{anchor_title}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "纪念主文本",
            token: "{{anchor_primary}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "纪念副文本",
            token: "{{anchor_secondary}}"
        )
    ]
}