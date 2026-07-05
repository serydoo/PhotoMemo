#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum ConfigurationSnapshotBuilder {

    static func build(
        from session: ConfigurationSession
    ) -> ConfigurationSnapshot? {
        guard
            let subject =
                session.state.selectedSubject
        else {
            return nil
        }

        return build(
            from: subject,
            smartModuleCarrierRegion:
                session.smartModuleCarrierRegion
        )
    }

    static func build(
        from subject: MemorySubject,
        smartModuleCarrierRegion: CardRegion = .slotD
    ) -> ConfigurationSnapshot {
        ConfigurationSnapshot(
            subjectID: subject.id,
            memorySubject: subject,
            expression:
                subject.behavior.memoryExpression,
            decorations: subject.decorations,
            primaryAnchor:
                memoryAnchor(
                    from: subject.primaryTimeAnchor
                ),
            smartModuleCarrierRegion:
                smartModuleCarrierRegion
        )
    }
}

private extension ConfigurationSnapshotBuilder {

    static func memoryAnchor(
        from anchor: MemorySubject.TimeAnchor?
    ) -> MemoryAnchor? {
        guard let anchor else {
            return nil
        }

        return MemoryAnchor(
            id: anchor.id,
            title: anchor.title,
            date: anchor.date,
            anchorType:
                anchor.resolvedAnchorType,
            expressionStyle:
                anchor.resolvedExpressionStyle
        )
    }
}
#endif
