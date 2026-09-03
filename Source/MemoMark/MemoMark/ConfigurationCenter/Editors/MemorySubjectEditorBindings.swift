#if !MEMOMARK_SHARE_EXTENSION
import SwiftUI

extension Binding where Value == MemorySubject.TimeAnchor {

    var title: Binding<String> {
        Binding<String>(
            get: { wrappedValue.title },
            set: { wrappedValue.title = $0 }
        )
    }

    var date: Binding<Date> {
        Binding<Date>(
            get: { wrappedValue.date },
            set: { wrappedValue.date = $0 }
        )
    }

    var note: Binding<String> {
        Binding<String>(
            get: { wrappedValue.note },
            set: { wrappedValue.note = $0 }
        )
    }

    var anchorType: Binding<AnchorType> {
        Binding<AnchorType>(
            get: { wrappedValue.resolvedAnchorType },
            set: {
                wrappedValue.anchorType = $0
                wrappedValue.expressionStyle =
                    MemoryAnchorExpressionStyle.defaultStyle(for: $0)
            }
        )
    }
}

#endif
