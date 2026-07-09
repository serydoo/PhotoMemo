#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1ConfigurationBootstrapProjection:
    Hashable {

    let customLogoBadge:
        Badge?

    let logoMode:
        V1LogoMode

    let outputTarget:
        V1IOSOutputTarget

    let mediaOutputMode:
        V1MediaOutputMode

    let selectedExistingAlbumIdentifier:
        String

    let suggestedNewAlbumName:
        String?

    let locationDisplayConfiguration:
        ExpressionModuleConfiguration?
}

enum V1ConfigurationBootstrapPresenter {

    static func projection(
        from state:
            V1ConfigurationBootstrapState
    ) -> V1ConfigurationBootstrapProjection {

        V1ConfigurationBootstrapProjection(
            customLogoBadge:
                state.logoMode == .customUpload
                ? state.customLogoBadge
                : nil,
            logoMode:
                state.logoMode,
            outputTarget:
                state.outputTarget,
            mediaOutputMode:
                state.mediaOutputMode,
            selectedExistingAlbumIdentifier:
                state
                .selectedExistingAlbumIdentifier,
            suggestedNewAlbumName:
                state
                .suggestedNewAlbumName,
            locationDisplayConfiguration:
                state
                .locationDisplayConfiguration
        )
    }
}
#endif
