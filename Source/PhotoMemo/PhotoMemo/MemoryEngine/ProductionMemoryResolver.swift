import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct ProductionMemoryPayload:
    Hashable {

    var subject: MemorySubject
    var snapshot: ConfigurationSnapshot
    var module: MemoryModule
}

struct ProductionMemoryResolver {

    private let defaults: UserDefaults

    init(
        defaults: UserDefaults =
            PhotoMemoSharedContainer.sharedUserDefaults
    ) {
        self.defaults = defaults
    }

    func resolve(
        photo: SelectedPhoto,
        configuration: BatchConfigurationSnapshot
    ) -> ProductionMemoryPayload {
        let profile =
            loadProfile()
            ?? PersonalProfile()
        let anchors =
            configuration.anchor.map {
                [$0]
            } ?? []
        let subject =
            MemorySubjectAdapter.adapt(
                profile: profile,
                anchors: anchors,
                selectedAnchorID:
                    configuration.anchor?.id,
                referenceDate:
                    photo.metadata.captureDate
            )
        let snapshot =
            ConfigurationSnapshotBuilder
            .build(from: subject)
        let module =
            MemoryExpressionEngine()
            .generateModule(
                context:
                    MemoryExpressionContext(
                        subject: subject,
                        snapshot: snapshot,
                        captureDate:
                            photo.metadata.captureDate
                    )
            )

        return ProductionMemoryPayload(
            subject: subject,
            snapshot: snapshot,
            module: module
        )
    }
}

private extension ProductionMemoryResolver {

    func loadProfile() -> PersonalProfile? {
        guard
            let data = defaults.data(
                forKey: "photomemo.personalProfile"
            )
        else {
            return nil
        }

        return try? JSONDecoder().decode(
            PersonalProfile.self,
            from: data
        )
    }
}
#endif
