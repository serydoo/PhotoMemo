import SwiftUI

struct RecordCardRenderer: View {

    enum Destination: Equatable {

        case classicWhite
    }

    let image: Image

    let card: RecordCard

    var body: some View {

        ClassicWhiteCardRenderer(
            image: image,
            card: card
        )
    }

    static func destination(
        for preset: TemplatePreset
    ) -> Destination {

        .classicWhite
    }
}
