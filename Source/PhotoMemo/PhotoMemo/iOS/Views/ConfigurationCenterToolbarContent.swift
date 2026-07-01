#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct ConfigurationCenterToolbarContent: ToolbarContent {

    let presentation: ConfigurationCenterPageChromePresentation
    let onReset: () -> Void
    let onApply: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            VStack(alignment: .leading, spacing: 1) {
                Text(presentation.sectionTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary)

                Text(presentation.statusText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(presentation.resetActionTitle) {
                onReset()
            }
            .font(.caption.weight(.semibold))

            Button {
                onApply()
            } label: {
                Label(
                    presentation.primaryActionTitle,
                    systemImage:
                        presentation
                        .primaryActionSystemImage
                )
            }
            .font(.caption.weight(.semibold))
            .disabled(!presentation.canApplyChanges)
        }
    }
}
#endif
