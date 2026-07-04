#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

extension MemorySubject.TimeAnchor {

    var resolvedAnchorType: AnchorType {
        anchorType ?? .birthday
    }

    var resolvedExpressionStyle:
        MemoryAnchorExpressionStyle {
        MemoryAnchorExpressionStyle
            .resolvedStyle(
                for: resolvedAnchorType,
                candidate: expressionStyle
            )
    }

    var normalizedForEditing: Self {
        var normalized = self
        normalized.anchorType =
            resolvedAnchorType
        normalized.expressionStyle =
            resolvedExpressionStyle
        return normalized
    }
}
#endif
