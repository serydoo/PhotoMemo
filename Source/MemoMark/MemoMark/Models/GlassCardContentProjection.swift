import Foundation

/// Positional content carried by the structured GlassCard study.
///
/// These names identify the four existing card-template areas, not fixed field
/// meanings. Each area's actual text and variables remain authored by its
/// TemplateItems. This is a runtime projection only; no new persistence schema
/// is introduced by this projection.
struct GlassCardContentProjection: Equatable {

    var leftTop: String
    var leftBottom: String
    var rightTop: String
    var rightBottom: String

    init(
        leftTop: String,
        leftBottom: String,
        rightTop: String,
        rightBottom: String
    ) {
        self.leftTop = leftTop
        self.leftBottom = leftBottom
        self.rightTop = rightTop
        self.rightBottom = rightBottom
    }

    var isEmpty: Bool {
        [leftTop, leftBottom, rightTop, rightBottom].allSatisfy {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
