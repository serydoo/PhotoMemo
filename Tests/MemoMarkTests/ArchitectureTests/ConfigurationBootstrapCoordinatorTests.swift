#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Configuration bootstrap coordinator")
struct ConfigurationBootstrapCoordinatorTests {

    @Test("loadState prefers coordinator-backed bootstrap when available")
    func loadStatePrefersCoordinatorBackedBootstrapWhenAvailable() {
        let expected =
            ConfigurationBootstrapState(
                customLogoBadge: .appleClassic,
                logoMode: .customUpload,
                outputTarget: .existingAlbum,
                selectedExistingAlbumIdentifier:
                    "album-1",
                suggestedNewAlbumName:
                    "成长记录"
            )

        let coordinator =
            ConfigurationBootstrapCoordinator(
                loadFromCoordinator: {
                    .success(expected)
                },
                fallbackLoad: {
                    Issue.record(
                        "Fallback should not load on coordinator success."
                    )
                    return ConfigurationBootstrapState(
                        customLogoBadge: nil,
                        logoMode: .appleMini,
                        outputTarget: .automatic,
                        selectedExistingAlbumIdentifier:
                            "",
                        suggestedNewAlbumName: nil
                    )
                }
            )

        #expect(
            coordinator.loadState()
            == expected
        )
    }

    @Test("loadState falls back when coordinator bootstrap fails")
    func loadStateFallsBackWhenCoordinatorBootstrapFails() {
        let fallback =
            ConfigurationBootstrapState(
                customLogoBadge: nil,
                logoMode: .appleMini,
                outputTarget: .newAlbum,
                selectedExistingAlbumIdentifier:
                    "",
                suggestedNewAlbumName:
                    "新相册"
            )

        let coordinator =
            ConfigurationBootstrapCoordinator(
                loadFromCoordinator: {
                    .failure(
                        MemoMarkError(
                            code: .configurationUnavailable,
                            message: "missing"
                        )
                    )
                },
                fallbackLoad: {
                    fallback
                }
            )

        #expect(
            coordinator.loadState()
            == fallback
        )
    }

    @Test("loadState uses fallback when no coordinator loader exists")
    func loadStateUsesFallbackWhenNoCoordinatorLoaderExists() {
        let fallback =
            ConfigurationBootstrapState(
                customLogoBadge: nil,
                logoMode: .appleMini,
                outputTarget: .automatic,
                selectedExistingAlbumIdentifier:
                    "",
                suggestedNewAlbumName: nil
            )

        let coordinator =
            ConfigurationBootstrapCoordinator(
                fallbackLoad: {
                    fallback
                }
            )

        #expect(
            coordinator.loadState()
            == fallback
        )
    }

    @Test("configuration-coordinator init with nil returns a pure default bootstrap state instead of reading settings directly")
    func configurationCoordinatorInitWithNilReturnsPureDefaultBootstrapState() {
        let coordinator =
            ConfigurationBootstrapCoordinator(
                configurationCoordinator:
                    nil
            )

        #expect(
            coordinator.loadState()
            == ConfigurationBootstrapState(
                customLogoBadge: nil,
                logoMode: .appleMini,
                outputTarget: .automatic,
                selectedExistingAlbumIdentifier:
                    "",
                suggestedNewAlbumName: nil
            )
        )
    }
}
#endif
