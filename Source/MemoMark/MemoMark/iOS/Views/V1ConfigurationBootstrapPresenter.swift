#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct ConfigurationBootstrapProjection:
    Hashable {

    let customLogoBadge:
        Badge?

    let logoMode:
        ConfigurationLogoMode

    let outputTarget:
        ConfigurationOutputTarget

    let mediaOutputMode:
        MediaOutputMode

    let selectedExistingAlbumIdentifier:
        String

    let suggestedNewAlbumName:
        String?

    let locationDisplayConfiguration:
        ExpressionModuleConfiguration?
}

enum ConfigurationBootstrapPresenter {

    static func projection(
        from state:
            ConfigurationBootstrapState
    ) -> ConfigurationBootstrapProjection {

        ConfigurationBootstrapProjection(
            customLogoBadge:
                state.logoMode == .customUpload
                ? state.customLogoBadge
                : nil,
            logoMode:
                state.logoMode,
            outputTarget:
                state.outputTarget,
            mediaOutputMode:
                // The media mode remains decodable for old installations,
                // but the current product contract is source-compatible:
                // input media determines whether the output is still or
                // motion-preserving.
                .originalFormat,
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
