#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Combine

@MainActor
final class ConfigurationSession:
    ObservableObject {

    @Published
    var state: ConfigurationCenterState

    init(
        state: ConfigurationCenterState? = nil
    ) {
        self.state = state ?? .mock
    }

    func selectSubject(
        _ subject: MemorySubject
    ) {
        state.selectedSubjectID = subject.id
        selectRegion(.subject)
    }

    func selectRegion(
        _ region: CardRegion
    ) {
        select(
            CardRegionBehavior(region: region)
        )
    }

    func select(
        _ behavior: CardRegionBehavior
    ) {
        state.cardSelection.select(behavior.region)
        if behavior.region != .slotD {
            state.selectedBlockID = nil
        }
    }

    func hoverRegion(
        _ region: CardRegion?
    ) {
        state.cardSelection.hover(region)
    }

    func selectBlock(
        _ block: MemoryBlock
    ) {
        state.selectedBlockID = block.id
        state.selectedRegion = .slotD
    }

    func insertBlock(
        _ block: MemoryBlock
    ) {
        guard let subjectIndex = selectedSubjectIndex else {
            return
        }

        state.subjects[subjectIndex]
            .behavior.memoryExpression.blocks
            .append(block)
    }

    func removeBlock(
        _ block: MemoryBlock
    ) {
        guard let subjectIndex = selectedSubjectIndex else {
            return
        }

        state.subjects[subjectIndex]
            .behavior.memoryExpression.blocks
            .removeAll {
                $0.id == block.id
            }
    }

    func moveBlock(
        _ block: MemoryBlock,
        direction: Int
    ) {
        guard let subjectIndex = selectedSubjectIndex else {
            return
        }

        var blocks =
            state.subjects[subjectIndex]
            .behavior.memoryExpression.blocks

        guard
            let currentIndex =
                blocks.firstIndex(where: {
                    $0.id == block.id
                })
        else {
            return
        }

        let targetIndex =
            min(
                max(currentIndex + direction, 0),
                blocks.count - 1
            )

        guard currentIndex != targetIndex else {
            return
        }

        let movedBlock =
            blocks.remove(at: currentIndex)
        blocks.insert(
            movedBlock,
            at: targetIndex
        )
        state.subjects[subjectIndex]
            .behavior.memoryExpression.blocks = blocks
        state.selectedBlockID = block.id
    }

    func selectDecoration(
        _ decoration: DecorationAsset
    ) {
        guard let subjectIndex = selectedSubjectIndex else {
            return
        }

        state.subjects[subjectIndex]
            .decorations
            .removeAll {
                $0.kind == decoration.kind
            }
        state.subjects[subjectIndex]
            .decorations
            .append(decoration)
    }

    private var selectedSubjectIndex: Int? {
        guard let subject = state.selectedSubject else {
            return nil
        }

        return state.subjects.firstIndex {
            $0.id == subject.id
        }
    }
}

extension ConfigurationCenterState {

    static var mock: ConfigurationCenterState {
        let expression =
            MemoryExpression(
                title: "Birthday Memory",
                blocks: [
                    .text(""),
                    MemoryBlock(
                        type: .memory,
                        title: "Nickname",
                        value: "昵称"
                    ),
                    .text(" 今天 "),
                    MemoryBlock(
                        type: .memory,
                        title: "Age",
                        value: "年龄"
                    ),
                    .text(" 啦")
                ]
            )

        let icon =
            DecorationAsset(
                kind: .icon,
                title: "Heart",
                systemSymbolName: "heart.fill"
            )

        let badge =
            DecorationAsset(
                kind: .badge,
                title: "Milestone",
                systemSymbolName: "seal.fill"
            )

        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "Tutu",
                        shortName: "Tutu"
                    ),
                relationship:
                    .init(
                        role: "Family",
                        label: "家人"
                    ),
                referenceDate:
                    Calendar.current.date(
                        from:
                            DateComponents(
                                year: 2024,
                                month: 4,
                                day: 18
                            )
                    ) ?? Date(),
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "Birthday",
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
                        role: "Travel",
                        label: "旅行"
                    ),
                referenceDate:
                    Calendar.current.date(
                        from:
                            DateComponents(
                                year: 2025,
                                month: 3,
                                day: 29
                            )
                    ) ?? Date(),
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "First Visit",
                        iconStrategy: .fixed,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            MemoryExpression(
                                title: "Travel Memory",
                                blocks: [
                                    MemoryBlock(
                                        type: .memory,
                                        title: "Life Anchor",
                                        value: "Life Anchor"
                                    ),
                                    .text(" · "),
                                    MemoryBlock(
                                        type: .photo,
                                        title: "Capture Date",
                                        value: "拍摄日期"
                                    )
                                ]
                            )
                    ),
                decorations: [
                    DecorationAsset(
                        kind: .icon,
                        title: "Map",
                        systemSymbolName: "map.fill"
                    )
                ]
            )

        let decorations = [
            icon,
            badge,
            DecorationAsset(
                kind: .icon,
                strategy: .fixed,
                title: "Star",
                systemSymbolName: "star.fill"
            ),
            DecorationAsset(
                kind: .badge,
                strategy: .autoMatch,
                title: "Ribbon",
                systemSymbolName: "rosette"
            ),
            DecorationAsset(
                kind: .future,
                strategy: .none,
                title: "Future Decoration",
                systemSymbolName: "sparkles"
            )
        ]

        return ConfigurationCenterState(
            subjects: [
                subject,
                travelSubject
            ],
            selectedSubjectID: subject.id,
            cardSelection: .defaultSelection,
            selectedBlockID: nil,
            tokenLibrary: TokenLibrary(),
            availableDecorations: decorations
        )
    }
}
#endif
