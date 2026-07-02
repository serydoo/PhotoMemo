#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum IOSConfigurationPanel:
    Hashable {

    case subject
    case card(CardRegion)
    case memoryModule
    case output
    case configurationGuide
}
#endif
