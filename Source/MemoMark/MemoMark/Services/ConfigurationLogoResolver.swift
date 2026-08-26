#if !MEMOMARK_SHARE_EXTENSION
import Foundation

enum ConfigurationLogoResolver {

    static func badge(
        from logo: MemoryConfigurationRecord.Presentation.Logo,
        subject: MemorySubject?
    ) -> Badge? {
        switch logo.mode {
        case .appleMini:
            return nil
        case .customUpload:
            return badge(from: logo.badge)
        case .subjectAvatar:
            return subjectAvatarBadge(from: subject)
        }
    }

    private static func badge(
        from descriptor:
            MemoryConfigurationRecord.Presentation.Logo.BadgeDescriptor?
    ) -> Badge? {
        guard let descriptor,
              let reference = descriptor.assetReference else {
            return nil
        }
        return Badge(
            id: descriptor.id,
            name: descriptor.name,
            type: descriptor.type,
            imageName: descriptor.imageName,
            imagePath: ConfigurationSubjectAssetMapper()
                .makeRuntimePath(
                    reference.relativePath
                ),
            systemSymbol: descriptor.systemSymbol,
            isSystemDefault: descriptor.isSystemDefault
        )
    }

    private static func subjectAvatarBadge(
        from subject: MemorySubject?
    ) -> Badge? {
        guard let subject else {
            return nil
        }
        let imagePath = ConfigurationSubjectAssetMapper()
            .makeRuntimePath(
                subject.identity.avatarBadgeImagePath
                ?? subject.identity.avatarImagePath
            )
        guard let imagePath else {
            return nil
        }
        return Badge(
            name: OptimizedSubjectAvatarAsset
                .subjectAvatarBadgeName,
            type: .customUpload,
            imagePath: imagePath,
            isSystemDefault: false
        )
    }
}
#endif
