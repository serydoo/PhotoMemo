import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("PhotoProcessingInputPolicy")
struct PhotoProcessingInputPolicyTests {

    @Test("Supports the still-image formats used by the MVP pipeline")
    func supportsMVPStillImageFormats() {

        let policy = PhotoProcessingInputPolicy.standard

        #expect(policy.isSupportedContentType(.jpeg))
        #expect(policy.isSupportedContentType(.heic))
        #expect(policy.isSupportedContentType(.heif))
        #expect(policy.isSupportedContentType(.png))
        #expect(policy.isSupportedContentType(.tiff))
    }

    @Test("Rejects unsupported animated raw web and video formats")
    func rejectsUnsupportedFormats() {

        let policy = PhotoProcessingInputPolicy.standard

        #expect(!policy.isSupportedContentType(.gif))
        #expect(!policy.isSupportedContentType(.webP))
        #expect(!policy.isSupportedContentType(.movie))
        #expect(!policy.isSupportedContentType(UTType("com.adobe.raw-image")))
        #expect(!policy.isSupportedContentType(UTType("com.adobe.digital-negative")))
    }

    @Test("Rejects Live Photo packages explicitly")
    func rejectsLivePhotos() throws {

        let livePhotoType =
            try #require(
                UTType("com.apple.live-photo")
            )
        let verdict =
            PhotoProcessingInputPolicy.standard.verdict(
                contentType: livePhotoType,
                pixelWidth: 4032,
                pixelHeight: 3024
            )

        #expect(!verdict.isSupported)
        #expect(verdict.reason == .livePhoto)
        #expect(verdict.title == "暂不支持 Live Photo")
    }

    @Test("Accepts current highest standard iPhone still-photo dimensions")
    func acceptsHighestStandardIPhoneStillPhotoDimensions() {

        let verdict =
            PhotoProcessingInputPolicy.standard.verdict(
                contentType: .heic,
                pixelWidth: 8064,
                pixelHeight: 6048
            )

        #expect(verdict.isSupported)
    }

    @Test("Accepts portrait photos using the same long-side aspect ratio rule")
    func acceptsPortraitPhotosUsingLongSideRatio() {

        let portraitVerdict =
            PhotoProcessingInputPolicy.standard.verdict(
                contentType: .heic,
                pixelWidth: 6048,
                pixelHeight: 8064
            )

        let verticalVideoRatioVerdict =
            PhotoProcessingInputPolicy.standard.verdict(
                contentType: .jpeg,
                pixelWidth: 3024,
                pixelHeight: 5376
            )

        #expect(portraitVerdict.isSupported)
        #expect(verticalVideoRatioVerdict.isSupported)
    }

    @Test("Reads file dimensions when validating copied intake files")
    func validatesCopiedIntakeFilesFromImageProperties() throws {

        let fixtureURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .portraitJPEG
            )

        let verdict =
            PhotoProcessingInputPolicy.standard.verdict(
                fileURL: fixtureURL,
                declaredContentTypeIdentifier:
                    UTType.image.identifier
            )

        #expect(verdict.isSupported)
    }

    @Test("Rejects images larger than the standard iPhone still-photo envelope")
    func rejectsOversizedImages() {

        let dimensionVerdict =
            PhotoProcessingInputPolicy.standard.verdict(
                contentType: .jpeg,
                pixelWidth: 9000,
                pixelHeight: 6000
            )

        #expect(!dimensionVerdict.isSupported)
        #expect(dimensionVerdict.reason == .oversizedPixelDimension)

        let countVerdict =
            PhotoProcessingInputPolicy.standard.verdict(
                contentType: .jpeg,
                pixelWidth: 8064,
                pixelHeight: 7000
            )

        #expect(!countVerdict.isSupported)
        #expect(countVerdict.reason == .oversizedPixelCount)
    }

    @Test("Rejects extreme panorama or long-screenshot aspect ratios")
    func rejectsExtremeAspectRatios() {

        let verdict =
            PhotoProcessingInputPolicy.standard.verdict(
                contentType: .jpeg,
                pixelWidth: 6000,
                pixelHeight: 1200
            )

        #expect(!verdict.isSupported)
        #expect(verdict.reason == .extremeAspectRatio)
    }
}
