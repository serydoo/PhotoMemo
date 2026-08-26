import CoreGraphics

/// Renderer-neutral visual output consumed by still and motion composers.
///
/// `FixedFooterOverlayDescriptor` remains a source-compatible alias below;
/// new renderers must describe their layers here rather than adding media
/// encoder branches.
struct PresentationArtifact {

    struct Layer {
        let frame: CGRect
        let image: CGImage
        let zIndex: Int
        let opacity: CGFloat

        init(
            frame: CGRect,
            image: CGImage,
            zIndex: Int = 0,
            opacity: CGFloat = 1
        ) {
            self.frame = frame
            self.image = image
            self.zIndex = zIndex
            self.opacity = min(max(opacity, 0), 1)
        }
    }

    enum CanvasBackground: Equatable {
        case transparent
        case opaqueWhite
    }

    /// Compatibility marker for pre-V4 callers. New code must express
    /// placement through layer frames, not this enum.
    enum Placement: Equatable {
        case footer
        case floating
    }

    let canvasSize: CGSize
    let photoFrame: CGRect
    let footerFrame: CGRect
    let footerImage: CGImage
    let layers: [Layer]
    let placement: Placement
    let canvasBackground: CanvasBackground

    /// Compatibility initializer for the former footer-only descriptor.
    /// Renderer implementations should prefer `init(canvasSize:photoFrame:layers:canvasBackground:)`.
    init(
        canvasSize: CGSize,
        photoFrame: CGRect,
        footerFrame: CGRect,
        footerImage: CGImage,
        placement: Placement = .footer,
        canvasBackground: CanvasBackground? = nil,
        layers: [Layer]? = nil
    ) throws {
        guard
            canvasSize.width > 0,
            canvasSize.height > 0,
            photoFrame.width > 0,
            photoFrame.height > 0,
            footerFrame.width > 0,
            footerFrame.height > 0
        else {
            throw LivePhotoVideoCompositionError.invalidOverlayGeometry
        }

        let canvasBounds = CGRect(origin: .zero, size: canvasSize)

        guard canvasBounds.contains(photoFrame),
              canvasBounds.contains(footerFrame) else {
            throw LivePhotoVideoCompositionError.invalidOverlayGeometry
        }

        if placement == .footer,
           photoFrame.intersection(footerFrame).height > 0,
           photoFrame.intersection(footerFrame).width > 0 {
            throw LivePhotoVideoCompositionError.invalidOverlayGeometry
        }

        self.canvasSize = canvasSize
        self.photoFrame = photoFrame
        self.footerFrame = footerFrame
        self.footerImage = footerImage
        self.layers = layers ?? [Layer(frame: footerFrame, image: footerImage)]
        self.placement = placement
        self.canvasBackground =
            canvasBackground
            ?? (placement == .footer ? .opaqueWhite : .transparent)
    }

    init(
        canvasSize: CGSize,
        photoFrame: CGRect,
        layers: [Layer],
        canvasBackground: CanvasBackground
    ) throws {
        guard !layers.isEmpty else {
            throw LivePhotoVideoCompositionError.invalidOverlayGeometry
        }

        let firstLayer = layers[0]
        try self.init(
            canvasSize: canvasSize,
            photoFrame: photoFrame,
            footerFrame: firstLayer.frame,
            footerImage: firstLayer.image,
            canvasBackground: canvasBackground,
            layers: layers
        )
    }
}

/// Compatibility name for the V3/V4 migration surface. Keep it only at
/// boundaries that have not yet migrated; do not add new footer-specific API.
typealias FixedFooterOverlayDescriptor = PresentationArtifact

extension PresentationArtifact {

    /// Returns the immutable layout artifact after validation. Encoder code
    /// may validate canonical geometry, but it must not silently recompute it.
    func validatedForEncoder() throws -> PresentationArtifact {
        let canvasBounds = CGRect(origin: .zero, size: canvasSize)
        guard
            isEncoderSafe(canvasSize.width),
            isEncoderSafe(canvasSize.height),
            canvasBounds.contains(photoFrame),
            photoFrame.width > 0,
            photoFrame.height > 0,
            canvasBounds.contains(footerFrame),
            footerFrame.width > 0,
            footerFrame.height > 0,
            layers.allSatisfy({
                $0.frame.width > 0
                    && $0.frame.height > 0
                    && canvasBounds.contains($0.frame)
                    && $0.opacity > 0
            })
        else {
            throw LivePhotoVideoCompositionError.invalidOverlayGeometry
        }

        return self
    }

    func replacingGeometry(
        canvasSize: CGSize,
        photoFrame: CGRect,
        footerFrame: CGRect
    ) throws -> PresentationArtifact {
        if canvasSize == self.canvasSize,
           photoFrame == self.photoFrame,
           footerFrame == self.footerFrame {
            return self
        }

        let scaleX = canvasSize.width / max(self.canvasSize.width, 1)
        let scaleY = canvasSize.height / max(self.canvasSize.height, 1)
        let resizedLayers = try layers.map { layer in
            let frame = CGRect(
                x: layer.frame.minX * scaleX,
                y: layer.frame.minY * scaleY,
                width: layer.frame.width * scaleX,
                height: layer.frame.height * scaleY
            )
            guard CGRect(origin: .zero, size: canvasSize).contains(frame) else {
                throw LivePhotoVideoCompositionError.invalidOverlayGeometry
            }
            return Layer(
                frame: frame,
                image: layer.image,
                zIndex: layer.zIndex,
                opacity: layer.opacity
            )
        }
        return try PresentationArtifact(
            canvasSize: canvasSize,
            photoFrame: photoFrame,
            footerFrame: footerFrame,
            footerImage: footerImage,
            placement: placement,
            canvasBackground: canvasBackground,
            layers: resizedLayers
        )
    }

    @available(*, deprecated, message: "Layout Engine must provide encoder-safe geometry; use validatedForEncoder().")
    func normalizedForEncoder() throws -> FixedFooterOverlayDescriptor {
        let normalizedCanvasSize = CGSize(
            width: Self.normalizedEncoderDimension(canvasSize.width),
            height: Self.normalizedEncoderDimension(canvasSize.height)
        )
        let scaleX = normalizedCanvasSize.width / max(canvasSize.width, 1)
        let scaleY = normalizedCanvasSize.height / max(canvasSize.height, 1)
        let bounds = CGRect(origin: .zero, size: normalizedCanvasSize)
        let normalizedLayers = try layers.map { layer in
            let frame = CGRect(
                x: layer.frame.minX * scaleX,
                y: layer.frame.minY * scaleY,
                width: layer.frame.width * scaleX,
                height: layer.frame.height * scaleY
            )
            guard frame.width > 0, frame.height > 0, bounds.contains(frame) else {
                throw LivePhotoVideoCompositionError.invalidOverlayGeometry
            }
            return Layer(
                frame: frame,
                image: layer.image,
                zIndex: layer.zIndex,
                opacity: layer.opacity
            )
        }

        return try PresentationArtifact(
            canvasSize: normalizedCanvasSize,
            photoFrame: CGRect(
                x: photoFrame.minX * scaleX,
                y: photoFrame.minY * scaleY,
                width: photoFrame.width * scaleX,
                height: photoFrame.height * scaleY
            ),
            footerFrame: CGRect(
                x: footerFrame.minX * scaleX,
                y: footerFrame.minY * scaleY,
                width: footerFrame.width * scaleX,
                height: footerFrame.height * scaleY
            ),
            footerImage: footerImage,
            placement: placement,
            canvasBackground: canvasBackground,
            layers: normalizedLayers
        )
    }

    private func normalizedLayers(
        from layers: [Layer],
        scaleX: CGFloat,
        scaleY: CGFloat,
        canvasSize: CGSize
    ) throws -> [Layer] {
        let bounds = CGRect(origin: .zero, size: canvasSize)
        return try layers.map { layer in
            let frame = CGRect(
                x: layer.frame.minX * scaleX,
                y: layer.frame.minY * scaleY,
                width: layer.frame.width * scaleX,
                height: layer.frame.height * scaleY
            )
            guard frame.width > 0, frame.height > 0, bounds.contains(frame) else {
                throw LivePhotoVideoCompositionError.invalidOverlayGeometry
            }
            return Layer(
                frame: frame,
                image: layer.image,
                zIndex: layer.zIndex,
                opacity: layer.opacity
            )
        }
    }


    static func normalizedEncoderDimension(
        _ value: CGFloat
    ) -> CGFloat {
        let integerValue = max(Int(ceil(value)), 2)
        return CGFloat(integerValue + (integerValue % 2))
    }

    private func isEncoderSafe(_ value: CGFloat) -> Bool {
        value >= 2
            && value.rounded(.towardZero) == value
            && Int(value) % 2 == 0
    }
}
