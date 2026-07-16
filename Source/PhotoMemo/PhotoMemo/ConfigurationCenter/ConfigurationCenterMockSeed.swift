#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum ConfigurationCenterMockSeed {

    static func makeState() -> ConfigurationCenterState {
        let expression =
            MemoryExpression(
                title: "生日记忆",
                blocks: [
                    .text(""),
                    MemoryBlock(
                        type: .memory,
                        title: "昵称",
                        value: "昵称"
                    ),
                    .text(" 今天 "),
                    MemoryBlock(
                        type: .memory,
                        title: "年龄",
                        value: "年龄"
                    ),
                    .text(" 啦")
                ]
            )

        let icon =
            DecorationAsset(
                kind: .icon,
                title: "人物",
                systemSymbolName: "person.fill"
            )

        let badge =
            DecorationAsset(
                kind: .badge,
                title: "相机",
                systemSymbolName: "camera.fill"
            )

        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "小宝",
                        shortName: "小宝"
                    ),
                relationship:
                    .init(
                        role: "家庭",
                        label: "家人"
                    ),
                definition: "家庭成长记录的主要记忆对象。",
                referenceDate:
                    Calendar.current.date(
                        from:
                            DateComponents(
                                year: 2024,
                                month: 1,
                                day: 1
                            )
                    ) ?? Date(),
                timeAnchors: [
                    MemorySubject.TimeAnchor(
                        title: "生日",
                        date:
                            Calendar.current.date(
                                from:
                                    DateComponents(
                                        year: 2024,
                                        month: 1,
                                        day: 1
                                    )
                            ) ?? Date(),
                        note: "示例出生日期"
                    ),
                    MemorySubject.TimeAnchor(
                        title: "重要日子",
                        date:
                            Calendar.current.date(
                                from:
                                    DateComponents(
                                        year: 2024,
                                        month: 6,
                                        day: 1
                            )
                    ) ?? Date(),
                        note: "示例重要日期"
                    ),
                    MemorySubject.TimeAnchor(
                        title: "入园",
                        date:
                            Calendar.current.date(
                                from:
                                    DateComponents(
                                        year: 2028,
                                        month: 9,
                                        day: 1
                                    )
                            ) ?? Date(),
                        note: "示例入园日期"
                    )
                ],
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "生日",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .fixed,
                        memoryExpression: expression
                    ),
                decorations: [
                    icon,
                    badge
                ]
            )

        let decorations = [
            icon,
            badge,
            DecorationAsset(
                kind: .icon,
                strategy: .fixed,
                title: "标记",
                systemSymbolName: "flag.fill"
            ),
            DecorationAsset(
                kind: .badge,
                strategy: .autoMatch,
                title: "Apple",
                systemSymbolName: "apple.logo"
            ),
            DecorationAsset(
                kind: .future,
                strategy: .none,
                title: "未来装饰",
                systemSymbolName: "sparkles"
            )
        ]

        let preset1 =
            MemoryPreset(
                title: "成长记录",
                summary: "记录、时间线、拍摄参数和记忆表达使用第一套配置。",
                regionTemplateIDs: [
                    .slotA: "recorder.configuration1",
                    .slotB: "timeline.configuration1",
                    .slotC: "context.configuration1",
                    .slotD: "memory.configuration1"
                ],
                selectedSubjectID: subject.id,
                selectedTimeAnchorID: subject.timeAnchors[0].id
            )

        let preset2 =
            MemoryPreset(
                title: "重要日子",
                summary: "更强调日期、地点和纪念表达。",
                regionTemplateIDs: [
                    .slotA: "recorder.configuration2",
                    .slotB: "timeline.configuration2",
                    .slotC: "context.configuration2",
                    .slotD: "memory.configuration2"
                ],
                selectedSubjectID: subject.id,
                selectedTimeAnchorID: subject.timeAnchors[1].id
            )

        let preset3 =
            MemoryPreset(
                title: "自定义预设",
                summary: "预留给用户组合自己的区域配置。",
                regionTemplateIDs: [
                    .slotA: "recorder.configuration3",
                    .slotB: "timeline.configuration3",
                    .slotC: "context.configuration3",
                    .slotD: "memory.configuration3"
                ],
                selectedSubjectID: subject.id,
                selectedTimeAnchorID: subject.timeAnchors[1].id
            )

        return ConfigurationCenterState(
            subjects: [
                subject
            ],
            selectedSubjectID: subject.id,
            memoryPresets: [
                preset1,
                preset2,
                preset3
            ],
            selectedMemoryPresetID: preset1.id,
            cardSelection: .defaultSelection,
            selectedBlockID: nil,
            tokenLibrary: TokenLibrary(),
            availableDecorations: decorations,
            regionPreviewTexts: [
                .slotA: ConfigurationCenterPreviewDefaults
                    .defaultPreviewText(
                        for: .slotA,
                        subject: subject
                    ),
                .slotB: ConfigurationCenterPreviewDefaults
                    .defaultPreviewText(
                        for: .slotB,
                        subject: subject
                    ),
                .slotC: ConfigurationCenterPreviewDefaults
                    .defaultPreviewText(
                        for: .slotC,
                        subject: subject
                    ),
                .slotD: ConfigurationCenterPreviewDefaults
                    .defaultPreviewText(
                        for: .slotD,
                        subject: subject
                    )
            ]
        )
    }
}

extension ConfigurationCenterState {

    static var mock: ConfigurationCenterState {
        ConfigurationCenterMockSeed.makeState()
    }
}
#endif
