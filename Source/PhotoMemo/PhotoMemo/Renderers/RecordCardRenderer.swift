import SwiftUI

struct RecordCardRenderer: View {

    enum Destination: Equatable {

        case classicWhite

        case immersWhite
    }

    let image: Image

    let card: RecordCard

    var body: some View {

        switch Self.destination(
            for: card.template.preset
        ) {

        case .immersWhite:

            ImmersWhiteCardRenderer(
                image: image,
                card: card
            )

        case .classicWhite:

            ClassicWhiteCardRenderer(
                image: image,
                card: card
            )
        }
    }

    static func destination(
        for preset: TemplatePreset
    ) -> Destination {

        switch preset.renderLayout {

        case .classicWhite:
            return .classicWhite

        case .immersWhite:
            return .immersWhite
        }
    }
}
