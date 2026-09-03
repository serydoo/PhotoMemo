#if !MEMOMARK_SHARE_EXTENSION
import Testing
@testable import MemoMark

@Suite("Subject avatar editing draft")
struct SubjectAvatarEditingDraftTests {

    @Test("derived avatar paths stay together with their editing status")
    func derivedAvatarPathsStayTogetherWithEditingStatus() {
        var draft = SubjectAvatarEditingDraft()

        #expect(draft.hasAvatar == false)
        #expect(draft.previewPath == nil)
        #expect(
            draft.statusMessage
                == "可选择对象头像，用于头像、标识与预览。"
        )

        draft.applyOptimizedPaths(
            displayImagePath: "display.jpg",
            badgeImagePath: "badge.jpg",
            previewImagePath: "preview.jpg"
        )

        #expect(draft.hasAvatar)
        #expect(draft.previewPath == "preview.jpg")
        #expect(draft.displayImagePath == "display.jpg")
        #expect(draft.badgeImagePath == "badge.jpg")
        #expect(
            draft.statusMessage
                == "头像已优化并同步到头像、标识与预览资源。"
        )
    }

    @Test("restoring paths rebuilds the user-visible avatar state")
    func restoringPathsRebuildsUserVisibleAvatarState() {
        var draft = SubjectAvatarEditingDraft()

        draft.restore(
            displayImagePath: "display.jpg",
            badgeImagePath: nil,
            previewImagePath: nil
        )

        #expect(draft.hasAvatar)
        #expect(draft.previewPath == "display.jpg")
        #expect(
            draft.statusMessage
                == "已准备头像衍生资源，可用于头像、标识与预览。"
        )
    }

    @Test("projection writes all derived paths to subject identity together")
    func projectionWritesDerivedPathsTogether() {
        var draft = SubjectAvatarEditingDraft()
        draft.applyOptimizedPaths(
            displayImagePath: "display.png",
            badgeImagePath: "badge.png",
            previewImagePath: "preview.png"
        )
        var identity = MemorySubject.Identity(
            displayName: "对象",
            shortName: "对象"
        )

        draft.applying(to: &identity)

        #expect(identity.avatarImagePath == "display.png")
        #expect(identity.avatarBadgeImagePath == "badge.png")
        #expect(identity.avatarPreviewImagePath == "preview.png")
    }
}
#endif
