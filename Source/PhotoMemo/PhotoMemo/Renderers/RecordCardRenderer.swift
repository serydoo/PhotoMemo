import SwiftUI

struct RecordCardRenderer: View {

    enum Destination: Equatable {

        case classicWhite
        case minimal
    }

    let image: Image

    let card: RecordCard

    var body: some View {

        switch card.presentationStyle {
        case .classicWhite:
            ClassicWhiteCardRenderer(
                image: image,
                card: card
            )
        case .minimal:
            MinimalCardRenderer(
                image: image,
                card: card
            )
        }
    }

    static func destination(
        for preset: TemplatePreset
    ) -> Destination {

        .classicWhite
    }

    static func destination(
        for style: RecordCardPresentationStyle
    ) -> Destination {
        switch style {
        case .classicWhite: .classicWhite
        case .minimal: .minimal
        }
    }

    static func outputPixelSize(
        for card: RecordCard,
        fallbackSize: CGSize
    ) -> CGSize {
        RecordCardPresentationPlanner()
            .outputPixelSize(
                for: card,
                fallbackSize: fallbackSize
            )
    }
}
