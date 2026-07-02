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

    let selectedExistingAlbumIdentifier:
        String

    let suggestedNewAlbumName:
        String?
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
            selectedExistingAlbumIdentifier:
                state
                .selectedExistingAlbumIdentifier,
            suggestedNewAlbumName:
                state
                .suggestedNewAlbumName
        )
    }
}
#endif
