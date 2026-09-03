#if !MEMOMARK_SHARE_EXTENSION
import SwiftUI
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

private struct PlatformAvatarImage: View {

    let path: String

    var body: some View {
#if os(macOS)
        if let image = NSImage(contentsOfFile: path) {
            Image(nsImage: image)
                .resizable()
        } else {
            Color.clear
        }
#elseif canImport(UIKit)
        if let image = UIImage(contentsOfFile: path) {
            Image(uiImage: image)
                .resizable()
        } else {
            Color.clear
        }
#endif
    }
}

/// Shared avatar projection used by identity editing surfaces. It owns only
/// platform image loading and presentation; asset lifecycle remains in the
/// editor and optimizer boundaries.
struct SubjectAvatarPreview: View {

    let path: String?
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.10))

            if let path {
                PlatformAvatarImage(path: path)
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(
                        .system(
                            size: size * 0.38,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(width: size, height: size)
        .overlay(
            Circle()
                .stroke(ConfigurationUI.faintHairline)
        )
    }
}

#endif
