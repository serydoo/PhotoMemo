import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct MemoryAnchorTypeDefinition {

    let calculator: any MemoryCalculator
    let expressionProvider:
        any MemoryExpressionProvider
}

enum MemoryAnchorTypeRegistry {

    static func definition(
        for anchorType: AnchorType?
    ) -> MemoryAnchorTypeDefinition? {
        guard let anchorType else {
            return nil
        }

        switch anchorType {
        case .birthday:
            return MemoryAnchorTypeDefinition(
                calculator:
                    BirthdayAgeCalculator(),
                expressionProvider:
                    BirthdayAgeExpressionProvider()
            )
        case .relationship,
             .marriage,
             .exam,
             .custom:
            return nil
        }
    }
}
#endif
