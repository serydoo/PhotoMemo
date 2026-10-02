import CoreGraphics
import Foundation
import Testing
@testable import MemoMark

@Suite("Presentation backdrop material geometry")
struct PresentationBackdropMaterialTests {
    @Test func resizingPreservesMaterialAndScalesItsGeometry() throws {
        let artifact = try fixture()
        let resized = try artifact.replacingGeometry(canvasSize: CGSize(width: 200, height: 240),
            photoFrame: CGRect(x: 0, y: 0, width: 200, height: 240),
            footerFrame: CGRect(x: 0, y: 0, width: 200, height: 60))
        let material = try #require(resized.backdropMaterial)
        #expect(material.frame == CGRect(x: 10, y: 10, width: 180, height: 40))
        #expect(material.renderFrame == CGRect(x: 0, y: 0, width: 200, height: 60))
        #expect(material.cornerRadius == 20)
        _ = try resized.validatedForEncoder()
    }

    @Test func invalidMaterialCannotReachEncoder() throws {
        let material = PresentationArtifact.BackdropMaterial(
            frame: CGRect(x: 5, y: 5, width: 90, height: 20),
            renderFrame: CGRect(x: 0, y: 0, width: 50, height: 30), cornerRadius: 10)
        #expect(throws: LivePhotoVideoCompositionError.invalidOverlayGeometry) {
            _ = try fixture(material: material)
        }
    }

    @Test func nonfiniteCornerCannotReachEncoder() throws {
        let material = PresentationArtifact.BackdropMaterial(
            frame: CGRect(x: 5, y: 5, width: 90, height: 20),
            renderFrame: CGRect(x: 0, y: 0, width: 100, height: 30), cornerRadius: .nan)
        #expect(throws: LivePhotoVideoCompositionError.invalidOverlayGeometry) {
            _ = try fixture(material: material)
        }
    }

    @Test func existingArtifactsHaveNoBackdropMaterial() throws {
        #expect(try fixture(material: nil).backdropMaterial == nil)
    }

    @Test @MainActor func nativeMaterialPreservesPhotoOutsideItsBounds() throws {
        let artifact = try fixture()
        let source = try ImageEdgeAssertionSupport.solidImage(width: 100, height: 120, red: 170, green: 140, blue: 90)
        #expect(MemoMarkRenderedImageArtifactGuard.composingSourcePhoto(source, with: artifact) == nil)
        let plain = try #require(MemoMarkRenderedImageArtifactGuard.composingSourcePhoto(source, with: artifact, includeLayers: false))
        let result = try #require(MemoMarkRenderedImageArtifactGuard.composingSourcePhotoWithMaterial(source, with: artifact))
        let outside = CGRect(x: 0, y: 0, width: 100, height: 80)
        let original = try #require(plain.cropping(to: outside)?.dataProvider?.data)
        let actual = try #require(result.cropping(to: outside)?.dataProvider?.data)
        #expect((actual as Data) == (original as Data))
        let rail = CGRect(x: 5, y: 95, width: 90, height: 20)
        let sourceRail = try #require(plain.cropping(to: rail)?.dataProvider?.data)
        let nativeRail = try #require(result.cropping(to: rail)?.dataProvider?.data)
        #expect((sourceRail as Data) != (nativeRail as Data))
    }

    @Test @MainActor func materialSamplesEachSourceInsteadOfFreezingTheFirstPhoto() throws {
        let artifact = try fixture()
        let material = try #require(artifact.backdropMaterial)
        let light = try ImageEdgeAssertionSupport.solidImage(width: 100, height: 120, red: 220, green: 210, blue: 180)
        let dark = try ImageEdgeAssertionSupport.solidImage(width: 100, height: 120, red: 40, green: 30, blue: 20)
        let first = try #require(NativeBackdropMaterialRenderer.render(sourceCanvas: light, canvasSize: artifact.canvasSize, material: material))
        let next = try #require(NativeBackdropMaterialRenderer.render(sourceCanvas: dark, canvasSize: artifact.canvasSize, material: material))
        #expect(first.height == 30)
        #expect((try #require(first.dataProvider?.data) as Data) != (try #require(next.dataProvider?.data) as Data))
    }

    private func fixture(material: PresentationArtifact.BackdropMaterial? = .init(
        frame: CGRect(x: 5, y: 5, width: 90, height: 20),
        renderFrame: CGRect(x: 0, y: 0, width: 100, height: 30), cornerRadius: 10)
    ) throws -> PresentationArtifact {
        let context = try #require(CGContext(data: nil, width: 100, height: 30,
            bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        let image = try #require(context.makeImage())
        return try PresentationArtifact(canvasSize: CGSize(width: 100, height: 120),
            photoFrame: CGRect(x: 0, y: 0, width: 100, height: 120),
            layers: [.init(frame: CGRect(x: 0, y: 0, width: 100, height: 30), image: image)],
            canvasBackground: .transparent, backdropMaterial: material)
    }
}
