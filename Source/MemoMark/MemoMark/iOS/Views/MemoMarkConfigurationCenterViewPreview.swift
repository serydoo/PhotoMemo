#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

#Preview("iOS V4 预览") {
    let runtime =
        MemoMarkAppRuntime()

    MemoMarkConfigurationCenterView(
        dependencies:
            MemoMarkConfigurationCenterDependencies(
                runtime: runtime
            )
    )
}
#endif
