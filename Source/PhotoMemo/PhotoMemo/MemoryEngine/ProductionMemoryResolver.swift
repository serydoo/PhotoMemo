import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct ProductionMemoryPayload:
    Hashable {

    var subject: MemorySubject
    var snapshot: ConfigurationSnapshot
    var result: MemoryResult
    var module: MemoryModule
    var productionExpressionContext: ExpressionContext?
}

struct ProductionMemoryResolver {

    func resolve(
        photo: SelectedPhoto,
        frozenSnapshot snapshot: ConfigurationSnapshot
    ) -> ProductionMemoryPayload? {
        guard let subject =
            snapshot.memorySubject
        else {
            return nil
        }

        return resolve(
            photo: photo,
            subject: subject,
            snapshot: snapshot
        )
    }

    func resolveLegacyBatchConfiguration(
        photo: SelectedPhoto,
        configuration: BatchConfigurationSnapshot
    ) -> ProductionMemoryPayload {
        if let snapshot =
            configuration
            .canonicalProductionSnapshot {
            if let payload =
                resolve(
                    photo: photo,
                    frozenSnapshot: snapshot
                ) {
                return payload
            }
        }

        if let subject =
            configuration
            .legacyFrozenMemorySubject {
            let snapshot =
                ConfigurationSnapshotBuilder
                .build(from: subject)

            return resolve(
                photo: photo,
                subject: subject,
                snapshot: snapshot
            )
        }

        return resolveLegacyRuntimeDefaultsFallback(
            photo: photo,
            configuration: configuration
        )
    }
}

private extension ProductionMemoryResolver {

    func resolveLegacyRuntimeDefaultsFallback(
        photo: SelectedPhoto,
        configuration: BatchConfigurationSnapshot
    ) -> ProductionMemoryPayload {
        let profile =
            transportSubjectProjectionFallbackProfile(
                from: configuration
            )
        let legacyAnchor =
            configuration.legacyAnchor
        let anchors =
            legacyAnchor.map {
                [$0]
            } ?? []
        let subject =
            MemorySubjectAdapter.adapt(
                profile: profile,
                anchors: anchors,
                selectedAnchorID:
                    legacyAnchor?.id,
                referenceDate:
                    photo.metadata.captureDate
            )
        let snapshot =
            ConfigurationSnapshotBuilder
            .build(from: subject)

        return resolve(
            photo: photo,
            subject: subject,
            snapshot: snapshot
        )
    }

    func resolve(
        photo: SelectedPhoto,
        subject: MemorySubject,
        snapshot: ConfigurationSnapshot
    ) -> ProductionMemoryPayload {
        let completedSnapshot =
            snapshot.withMemorySubject(
                subject
            )
        let context =
            MemoryExpressionContext(
                subject: subject,
                snapshot: completedSnapshot,
                captureDate:
                    photo.metadata
                    .captureDate,
                captureCalendar:
                    photo.metadata
                    .captureCalendar
            )
        let resolved =
            resolvedMemory(
                context: context
            )

        return ProductionMemoryPayload(
            subject: subject,
            snapshot: completedSnapshot,
            result: resolved.result,
            module: resolved.module,
            productionExpressionContext:
            productionExpressionContext(
                from: context
            )
        )
    }

    func transportSubjectProjectionFallbackProfile(
        from configuration: BatchConfigurationSnapshot
    ) -> PersonalProfile {
        let subjectText =
            configuration
            .legacyMemorySubjectText?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        guard !subjectText.isEmpty else {
            return PersonalProfile()
        }

        return PersonalProfile(
            relationshipRole: .familyMember,
            babyNickname: subjectText
        )
    }

    func resolvedMemory(
        context: MemoryExpressionContext
    ) -> (
        result: MemoryResult,
        module: MemoryModule
    ) {
        let engine =
            MemoryExpressionEngine()
        let result =
            engine.generateResult(
                context: context
            )
        let module =
            MemoryResultPresentationAdapter()
            .makeModule(
                result: result,
                context: context
            )

        return (
            result,
            module
        )
    }

    func productionExpressionContext(
        from context: MemoryExpressionContext
    ) -> ExpressionContext? {
        guard let memoryValue =
            MemoryProvider()
            .expressionValue(
                for: MemoryProvider.memoryToken,
                context: context
            )
        else {
            return nil
        }

        return try? ExpressionContext(
            values: [
                memoryValue
            ]
        )
    }

}

private extension ConfigurationSnapshot {

    func withMemorySubject(
        _ subject: MemorySubject
    ) -> ConfigurationSnapshot {
        var copy = self
        if copy.memorySubject == nil {
            copy.memorySubject = subject
        }
        return copy
    }
}
#endif
