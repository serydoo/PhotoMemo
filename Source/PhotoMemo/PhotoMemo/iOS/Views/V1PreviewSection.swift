#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1PreviewSection: View {

    let logoMode: V1LogoMode
    let customLogoImagePath: String?
    let subjectAvatarLogoImagePath: String?
    let regionText: String
    let timeText: String
    let contextText: String
    let memoryText: String
    let onTap: (() -> Void)?

    var body: some View {
        V1PreviewCard(
            logoMode: logoMode,
            customLogoImagePath: customLogoImagePath,
            subjectAvatarLogoImagePath:
                subjectAvatarLogoImagePath,
            regionText: regionText,
            timeText: timeText,
            contextText: contextText,
            memoryText: memoryText
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}
#endif
