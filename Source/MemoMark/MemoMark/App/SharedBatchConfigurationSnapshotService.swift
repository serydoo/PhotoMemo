import Foundation

struct SharedBatchConfigurationSnapshotService {

    private let defaults: UserDefaults

    private let snapshotProvider:
        BatchConfigurationSnapshotProvider

    init(
        defaults: UserDefaults =
            MemoMarkSharedContainer
            .sharedUserDefaults
    ) {
        self.defaults = defaults
        self.snapshotProvider =
            BatchConfigurationSnapshotProvider(
                defaults: defaults
            )
    }

    func loadSnapshot() -> BatchConfigurationSnapshot {

        var snapshot = snapshotProvider.loadSnapshot()
#if os(iOS) && DEBUG && MEMOMARK_SHARE_EXTENSION
        // A bounded QA fixture changes only this durable request's output
        // semantics; it never saves over the user's configuration library.
        if #available(iOS 26.0, *),
           defaults.double(forKey: ContinuedProcessingSpike.productionEnabledUntilKey) > Date().timeIntervalSince1970,
           let description = defaults.string(forKey: ContinuedProcessingSpike.descriptionProbeValueKey),
           !description.isEmpty, description.count <= 64 {
            snapshot.shouldWritePhotoDescription = true
            snapshot.photoDescriptionOverride = description
            if defaults.double(forKey: ContinuedProcessingSpike.hostQueueUntilKey) > Date().timeIntervalSince1970 {
                // This opt-in fixture modifies transport output semantics without
                // modifying the user's durable revision. Do not claim it is that revision.
                snapshot = snapshot.asLegacyTransportCompatibility()
            }
        }
#endif
        return snapshot
    }

    func loadConfigurationReadiness()
    -> SavedConfigurationReadiness {

        snapshotProvider
            .loadConfigurationReadiness()
    }

    @available(*, deprecated, message: "Use loadConfigurationReadiness() instead.")
    func loadV1ConfigurationReadiness()
    -> SavedConfigurationReadiness {
        loadConfigurationReadiness()
    }

    func loadAnchorsResult()
    -> MemoMarkSharedDefaultsReadResult<
        [Anchor]
    > {

        snapshotProvider.loadAnchorsResult()
    }

    func loadTemplateResult()
    -> MemoMarkSharedDefaultsReadResult<
        Template
    > {

        snapshotProvider.loadTemplateResult()
    }

    func loadBadgeResult()
    -> MemoMarkSharedDefaultsReadResult<
        Badge
    > {

        snapshotProvider.loadBadgeResult()
    }

    func resolvedAlbumTitle(
        for identifier: String
    ) -> String? {

        snapshotProvider.resolvedAlbumTitle(
            for: identifier
        )
    }
}
