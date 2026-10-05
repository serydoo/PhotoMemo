import CoreGraphics
import SwiftUI

/// Native material consumes resolved geometry; it never chooses layout or content.
nonisolated enum NativeBackdropMaterialRenderer {
    static var isAvailable: Bool {
        if #available(iOS 26.0, macOS 26.0, *) { return true }
        return false
    }

    @MainActor
    static func render(sourceCanvas: CGImage, canvasSize: CGSize,
                       material: PresentationArtifact.BackdropMaterial) -> CGImage? {
        guard isAvailable, material.isValid(in: CGRect(origin: .zero, size: canvasSize)) else { return nil }
        let renderer = ImageRenderer(content: NativeBackdropMaterialCanvas(
            image: Image(decorative: sourceCanvas, scale: 1), canvasSize: canvasSize, material: material))
        renderer.scale = 1
        renderer.proposedSize = .init(canvasSize)
        guard let output = renderer.cgImage else { return nil }
        let frame = material.renderFrame
        return output.cropping(to: CGRect(x: frame.minX, y: canvasSize.height - frame.maxY,
                                         width: frame.width, height: frame.height))
    }
}

struct NativeBackdropMaterialCanvas: View {
    let image: Image
    let canvasSize: CGSize
    let material: PresentationArtifact.BackdropMaterial

    var body: some View {
        ZStack(alignment: .topLeading) {
            image.resizable().scaledToFill().frame(width: canvasSize.width, height: canvasSize.height).clipped()
            if #available(iOS 26.0, macOS 26.0, *) {
                Color.clear.frame(width: material.frame.width, height: material.frame.height)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: material.cornerRadius, style: .continuous))
                    .environment(\.colorScheme, .dark)
                    .opacity(0.88)
                    .offset(x: material.frame.minX, y: canvasSize.height - material.frame.maxY)
            }
        }.frame(width: canvasSize.width, height: canvasSize.height)
    }
}
