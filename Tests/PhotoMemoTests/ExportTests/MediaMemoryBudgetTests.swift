import Testing
import ImageIO
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("Media memory budget")
struct MediaMemoryBudgetTests {

    @Test("classifies standard still photos as normal cost")
    func classifiesStandardStillPhotosAsNormalCost() {
        let budget =
            MediaMemoryBudget(
                cost:
                    MediaCost(
                        pixelSize:
                            MediaPixelSize(
                                width: 4032,
                                height: 3024
                            ),
                        isRAW: false
                    )
            )

        #expect(budget.tier == .normal)
        #expect(budget.maxConcurrentDecodes == 2)
        #expect(budget.maxConcurrentRenders == 2)
        #expect(budget.maxConcurrentExports == 1)
    }

    @Test("reduces concurrency for high-resolution still photos")
    func reducesConcurrencyForHighResolutionStillPhotos() {
        let budget =
            MediaMemoryBudget(
                cost:
                    MediaCost(
                        pixelSize:
                            MediaPixelSize(
                                width: 6000,
                                height: 4000
                            ),
                        isRAW: false
                    )
            )

        #expect(budget.tier == .high)
        #expect(budget.maxConcurrentDecodes == 1)
        #expect(budget.maxConcurrentRenders == 1)
        #expect(budget.maxConcurrentExports == 1)
    }

    @Test("treats 48MP RAW assets as critical single-lane work")
    func treats48MPRawAssetsAsCriticalSingleLaneWork() {
        let budget =
            MediaMemoryBudget(
                cost:
                    MediaCost(
                        pixelSize:
                            MediaPixelSize(
                                width: 8064,
                                height: 6048
                            ),
                        isRAW: true
                    )
            )

        #expect(budget.tier == .critical)
        #expect(budget.requiresExtendedPreviewPreparation)
        #expect(budget.maxConcurrentDecodes == 1)
        #expect(budget.maxConcurrentRenders == 1)
        #expect(budget.maxConcurrentExports == 1)
    }

    @Test("derives cost from a media asset")
    func derivesCostFromMediaAsset() throws {
        let dngType =
            try #require(
                UTType(filenameExtension: "dng")
            )
        let asset =
            MediaAsset(
                fileURL:
                    URL(fileURLWithPath: "/tmp/IMG_9001.DNG"),
                sourceInfo:
                    PhotoSourceInfo(
                        originalFileName: "IMG_9001.DNG",
                        contentTypeIdentifier:
                            dngType.identifier
                    ),
                sourceProperties: [
                    kCGImagePropertyPixelWidth:
                        8064,
                    kCGImagePropertyPixelHeight:
                        6048
                ],
                contentType:
                    dngType
            )

        let cost =
            MediaCost(
                asset: asset
            )

        #expect(cost.pixelCount == 48_771_072)
        #expect(cost.isRAW)
        #expect(cost.estimatedDecodedByteCount == 195_084_288)
        #expect(
            MediaMemoryBudget(cost: cost).tier
            == .critical
        )
    }

    @Test("derives cost from file URL image properties")
    func derivesCostFromFileURLImageProperties() throws {
        let fixtureURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .portraitJPEG
            )
        let properties =
            try SyntheticFixtureLibrary.properties(
                at: fixtureURL
            )
        let expectedPixelSize =
            try #require(
                MediaPixelSize(
                    sourceProperties:
                        properties
                )
            )

        let cost =
            MediaCost(
                fileURL: fixtureURL,
                contentTypeIdentifier:
                    UTType.jpeg.identifier
            )

        #expect(cost.pixelSize == expectedPixelSize)
        #expect(
            cost.pixelCount
            == expectedPixelSize.width * expectedPixelSize.height
        )
        #expect(!cost.isRAW)
    }
}
