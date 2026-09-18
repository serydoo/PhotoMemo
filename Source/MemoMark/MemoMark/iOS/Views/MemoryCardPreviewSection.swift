#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct MemoryCardPreviewSection: View {

    let presentationStyle: RecordCardPresentationStyle
    let logoMode: ConfigurationLogoMode
    let customLogoImagePath: String?
    let subjectAvatarLogoImagePath: String?
    let regionText: String
    let timeText: String
    let contextText: String
    let memoryText: String
    let filmMarkOutputText: String
    let filmMarkConfiguration: FilmMarkConfiguration
    let onTap: (() -> Void)?

    var body: some View {
        MemoryCardPreviewSurface(
            presentationStyle: presentationStyle,
            logoMode: logoMode,
            customLogoImagePath: customLogoImagePath,
            subjectAvatarLogoImagePath:
                subjectAvatarLogoImagePath,
            regionText: regionText,
            timeText: timeText,
            contextText: contextText,
            memoryText: memoryText,
            filmMarkOutputText: filmMarkOutputText,
            filmMarkConfiguration: filmMarkConfiguration
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}
#endif
