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

        TemplateVariable(
            category: .recognized,
            title: "完整时间",
            token: "{{capture_date_display}}"
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

        // MARK: - Anchor

        TemplateVariable(
            category: .intelligent,
            title: "时间点名称",
            token: "{{anchor_title}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "通用结果",
            token: "{{anchor_primary}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "智能结果（自动匹配场景）",
            token: "{{anchor_smart_text}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "锚点日期",
            token: "{{anchor_secondary}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "完整摘要",
            token: "{{anchor_summary}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "纪念时长（X年X个月X天）",
            token: "{{anchor_duration_text}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "年岁（过去锚点，X岁X月X天）",
            token: "{{anchor_age_text}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "天数值（XX天）",
            token: "{{anchor_total_days_text}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "已过天数（过去锚点，已过XX天）",
            token: "{{anchor_elapsed_text}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "倒计时（未来锚点，还有XX天）",
            token: "{{anchor_countdown_text}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "第几天（第XX天）",
            token: "{{anchor_day_index_text}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "周数（XX周X天）",
            token: "{{anchor_week_text}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "月龄（XX个月）",
            token: "{{anchor_month_age_text}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "里程碑（100天 / 1周年）",
            token: "{{anchor_milestone_text}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "年数（数字）",
            token: "{{anchor_years}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "月数（数字）",
            token: "{{anchor_months}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "天数（数字）",
            token: "{{anchor_days}}"
        ),

        TemplateVariable(
            category: .intelligent,
            title: "总天数（数字）",
            token: "{{anchor_total_days}}"
        )
    ]
}
