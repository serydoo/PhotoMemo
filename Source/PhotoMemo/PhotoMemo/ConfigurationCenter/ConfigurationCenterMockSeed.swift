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
                        displayName: "途途",
                        shortName: "途途"
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
                                year: 2025,
                                month: 5,
                                day: 26
                            )
                    ) ?? Date(),
                timeAnchors: [
                    MemorySubject.TimeAnchor(
                        title: "生日",
                        date:
                            Calendar.current.date(
                                from:
                                    DateComponents(
                                        year: 2025,
                                        month: 5,
                                        day: 26
                                    )
                            ) ?? Date(),
                        note: "途途出生日期"
                    ),
                    MemorySubject.TimeAnchor(
                        title: "第一次旅行",
                        date:
                            Calendar.current.date(
                                from:
                                    DateComponents(
                                        year: 2025,
                                        month: 10,
                                        day: 2
                                    )
                            ) ?? Date(),
                        note: "途途第一次旅行"
                    ),
                    MemorySubject.TimeAnchor(
                        title: "入园",
                        date:
                            Calendar.current.date(
                                from:
                                    DateComponents(
                                        year: 2027,
                                        month: 9,
                                        day: 1
                                    )
                            ) ?? Date(),
                        note: "途途入园日期"
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

        let travelSubject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "Kyoto Spring",
                        shortName: "Kyoto"
                    ),
                relationship:
                    .init(
                        role: "旅行",
                        label: "旅行"
                    ),
                definition: "一次值得反复回看的旅行记忆。",
                referenceDate:
                    Calendar.current.date(
                        from:
                            DateComponents(
                                year: 2025,
                                month: 3,
                                day: 29
                            )
                    ) ?? Date(),
                timeAnchors: [
                    MemorySubject.TimeAnchor(
                        title: "出发",
                        date:
                            Calendar.current.date(
                                from:
                                    DateComponents(
                                        year: 2025,
                                        month: 3,
                                        day: 29
                                    )
                            ) ?? Date(),
                        note: "京都出发日期"
                    ),
                    MemorySubject.TimeAnchor(
                        title: "抵达",
                        date:
                            Calendar.current.date(
                                from:
                                    DateComponents(
                                        year: 2025,
                                        month: 3,
                                        day: 30
                                    )
                            ) ?? Date(),
                        note: "京都抵达日期"
                    ),
                    MemorySubject.TimeAnchor(
                        title: "回程",
                        date:
                            Calendar.current.date(
                                from:
                                    DateComponents(
                                        year: 2025,
                                        month: 4,
                                        day: 5
                                    )
                            ) ?? Date(),
                        note: "京都回程日期"
                    )
                ],
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "初次到访",
                        iconStrategy: .fixed,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            MemoryExpression(
                                title: "旅行记忆",
                                blocks: [
                                    MemoryBlock(
                                        type: .memory,
                                        title: "生命时间",
                                        value: "生命时间"
                                    ),
                                    .text(" · "),
                                    MemoryBlock(
                                        type: .photo,
                                        title: "拍摄日期",
                                        value: "拍摄日期"
                                    )
                                ]
                            )
                    ),
                decorations: [
                    DecorationAsset(
                        kind: .icon,
                        title: "位置",
                        systemSymbolName: "location.fill"
                    )
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
                title: "第一次旅行",
                summary: "更强调日期、地点和旅行记忆表达。",
                regionTemplateIDs: [
                    .slotA: "recorder.configuration2",
                    .slotB: "timeline.configuration2",
                    .slotC: "context.configuration2",
                    .slotD: "memory.configuration2"
                ],
                selectedSubjectID: travelSubject.id,
                selectedTimeAnchorID: travelSubject.timeAnchors[1].id
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
                subject,
                travelSubject
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
