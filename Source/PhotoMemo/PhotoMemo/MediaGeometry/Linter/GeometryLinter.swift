import CoreGraphics
import Foundation

struct GeometryLinter:
    Sendable {

    static let standard =
        GeometryLinter()

    func lint(
        _ geometry: CanonicalGeometry
    ) -> [GeometryIssue] {
        var issues: [GeometryIssue] = []

        if !geometry.facts.rawPixelSize.isPositiveFinite {
            issues.append(
                issue(
                    .invalidRawPixelSize,
                    "Raw pixel size must be positive and finite.",
                    location:
                        "facts.rawPixelSize"
                )
            )
        }

        if !geometry.facts.displaySize.isPositiveFinite {
            issues.append(
                issue(
                    .invalidDisplaySize,
                    "Display size must be positive and finite.",
                    location:
                        "facts.displaySize"
                )
            )
        }

        if !geometry.canvas.canvasSize.isPositiveFinite {
            issues.append(
                issue(
                    .invalidCanvas,
                    "Canvas size must be positive and finite.",
                    location:
                        "canvas.canvasSize"
                )
            )
        }

        let canvasBounds =
            CGRect(
                origin: .zero,
                size:
                    geometry
                    .canvas
                    .canvasSize
            )

        if !canvasBounds.contains(
            geometry
                .canvas
                .photoFrame
        ) {
            issues.append(
                issue(
                    .photoFrameOutsideCanvas,
                    "Photo frame must be inside the canvas.",
                    location:
                        "canvas.photoFrame"
                )
            )
        }

        if !canvasBounds.contains(
            geometry
                .canvas
                .footerFrame
        ) {
            issues.append(
                issue(
                    .footerOutsideCanvas,
                    "Footer frame must be inside the canvas.",
                    location:
                        "canvas.footerFrame"
                )
            )
        }

        if geometry.canvas.photoFrame.size
            != geometry.facts.displaySize {
            issues.append(
                issue(
                    .photoFrameDisplaySizeMismatch,
                    "Photo frame size must match display size.",
                    location:
                        "canvas.photoFrame"
                )
            )
        }

        if geometry.canvas.footerFrame.width
            != geometry.canvas.canvasSize.width {
            issues.append(
                issue(
                    .footerWidthMismatch,
                    "Footer frame width must match canvas width.",
                    location:
                        "canvas.footerFrame"
                )
            )
        }

        return issues
    }
}

private extension GeometryLinter {

    func issue(
        _ code: GeometryIssueCode,
        _ message: String,
        location: String?
    ) -> GeometryIssue {
        GeometryIssue(
            severity: .error,
            code: code,
            message: message,
            location: location
        )
    }
}

private extension CGSize {

    var isPositiveFinite: Bool {
        width.isFinite
            && height.isFinite
            && width > 0
            && height > 0
    }
}
