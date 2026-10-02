import CoreGraphics

/// Renderer-neutral visual output consumed by still and motion composers.
///
/// `FixedFooterOverlayDescriptor` remains a source-compatible alias below;
/// new renderers must describe their layers here rather than adding media
/// encoder branches.
nonisolated struct PresentationArtifact: Sendable {

    /// Source-dependent surface. Geometry is resolved by Layout, in media coordinates.
    struct BackdropMaterial: Equatable, Sendable {
        let frame: CGRect
        let renderFrame: CGRect
        let cornerRadius: CGFloat

        func isValid(in canvas: CGRect) -> Bool {
            [frame, renderFrame].allSatisfy {
                [$0.minX, $0.minY, $0.width, $0.height].allSatisfy(\.isFinite)
                    && $0.width > 0 && $0.height > 0 && canvas.contains($0)
            } && renderFrame.contains(frame) && cornerRadius.isFinite
                && cornerRadius > 0 && cornerRadius <= min(frame.width, frame.height) / 2
        }

        func scaled(x: CGFloat, y: CGFloat) -> Self {
            func scale(_ rect: CGRect) -> CGRect {
                CGRect(x: rect.minX * x, y: rect.minY * y,
                    width: rect.width * x, height: rect.height * y)
            }
            return .init(frame: scale(frame), renderFrame: scale(renderFrame),
                cornerRadius: cornerRadius * min(x, y))
        }
    }

    struct Layer: Sendable {
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

    enum CanvasBackground: Equatable, Sendable {
        case transparent
        case opaqueWhite
    }

    /// Compatibility marker for pre-V4 callers. New code must express
    /// placement through layer frames, not this enum.
    enum Placement: Equatable, Sendable {
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
    let backdropMaterial: BackdropMaterial?

    /// Compatibility initializer for the former footer-only descriptor.
    /// Renderer implementations should prefer `init(canvasSize:photoFrame:layers:canvasBackground:)`.
    init(
        canvasSize: CGSize,
        photoFrame: CGRect,
        footerFrame: CGRect,
        footerImage: CGImage,
        placement: Placement = .footer,
        canvasBackground: CanvasBackground? = nil,
        layers: [Layer]? = nil,
        backdropMaterial: BackdropMaterial? = nil
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

        guard backdropMaterial?.isValid(in: canvasBounds) != false else {
            throw LivePhotoVideoCompositionError.invalidOverlayGeometry
        }

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
        self.backdropMaterial = backdropMaterial
        self.placement = placement
        self.canvasBackground =
            canvasBackground
            ?? (placement == .footer ? .opaqueWhite : .transparent)
    }

    init(
        canvasSize: CGSize,
        photoFrame: CGRect,
        layers: [Layer],
        canvasBackground: CanvasBackground,
        placement: Placement = .floating,
        backdropMaterial: BackdropMaterial? = nil
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
            placement: placement,
            canvasBackground: canvasBackground,
            layers: layers,
            backdropMaterial: backdropMaterial
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
            backdropMaterial?.isValid(in: canvasBounds) != false,
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
            layers: resizedLayers,
            backdropMaterial: backdropMaterial?.scaled(x: scaleX, y: scaleY)
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
            layers: normalizedLayers,
            backdropMaterial: backdropMaterial?.scaled(x: scaleX, y: scaleY)
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
