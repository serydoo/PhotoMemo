#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum V1SubjectLibraryFactory {

    static func makeDefaultSubject(
        referenceDate: Date
    ) -> MemorySubject {
        let birthdayAnchor =
            MemorySubject.TimeAnchor(
                title: "生日",
                date: referenceDate,
                note: "请补充这个对象最重要的时间锚点。",
                anchorType: .birthday,
                expressionStyle:
                    .defaultStyle(for: .birthday)
            )

        return MemorySubject(
            identity: .init(
                displayName: "新的记忆对象",
                shortName: ""
            ),
            relationship: .init(
                role: "家人",
                label: "未设置"
            ),
            definition: "在这里补充对象身份、头像与时间锚点。",
            referenceDate: referenceDate,
            timeAnchors: [birthdayAnchor],
            activeTimeAnchorID: birthdayAnchor.id,
            expressionSubjectSource: .displayName,
            behavior: .init(
                primaryAnchor: birthdayAnchor.title,
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(
                    title: "生日记忆",
                    blocks: []
                )
            ),
            decorations: []
        )
    }
}

enum V1SubjectLibraryResolver {

    static func resolvedBootstrapSubject(
        subjects: [MemorySubject]?,
        selectedSubjectID: MemorySubject.ID?,
        fallbackSubject: MemorySubject?
    ) -> MemorySubject? {
        if let subjects,
           !subjects.isEmpty {
            if let selectedSubjectID,
               let selectedSubject =
                subjects.first(
                    where: {
                        $0.id == selectedSubjectID
                    }
                ) {
                return selectedSubject
            }

            return subjects.first
        }

        return fallbackSubject
    }

    static func subjectsForSaving(
        selectedSubject: MemorySubject?,
        subjects: [MemorySubject]
    ) -> [MemorySubject] {
        guard let selectedSubject else {
            return subjects
        }

        var resolvedSubjects = subjects
        if let index =
            resolvedSubjects.firstIndex(
                where: {
                    $0.id == selectedSubject.id
                }
            ) {
            resolvedSubjects[index] = selectedSubject
        } else {
            resolvedSubjects.append(selectedSubject)
        }

        return resolvedSubjects
    }

    static func persist(
        subjects: [MemorySubject],
        selectedSubjectID: MemorySubject.ID?,
        coordinator: ConfigurationCoordinator?
    ) {
        guard let coordinator else {
            return
        }

        _ =
            coordinator
            .saveV1SubjectLibrary(
                subjects: subjects,
                selectedSubjectID:
                    selectedSubjectID
            )
    }
}

@MainActor
enum V1SubjectLibraryMutationCoordinator {

    static func selectSubject(
        _ subjectID: MemorySubject.ID,
        in session: ConfigurationSession
    ) -> MemorySubject? {
        guard let subject =
            session.state.subjects.first(
                where: { $0.id == subjectID }
            ) else {
            return nil
        }

        session.selectSubject(subject)
        return subject
    }

    static func activateAnchor(
        _ anchorID: UUID,
        in session: ConfigurationSession
    ) -> MemorySubject.TimeAnchor? {
        guard
            var subject = session.state.selectedSubject,
            let anchor = subject.timeAnchor(id: anchorID)
        else {
            return nil
        }

        subject.activeTimeAnchorID = anchor.id
        subject.behavior.primaryAnchor = anchor.title
        subject.referenceDate = anchor.date
        session.updateSelectedSubject(subject)
        return anchor
    }

    static func addDefaultSubject(
        referenceDate: Date,
        to session: ConfigurationSession
    ) -> MemorySubject {
        let newSubject =
            V1SubjectLibraryFactory
            .makeDefaultSubject(
                referenceDate: referenceDate
            )

        session.appendSubject(newSubject)
        return newSubject
    }

    static func deleteCurrentSubject(
        from session: ConfigurationSession
    ) -> MemorySubject? {
        guard let selectedSubjectID =
            session.state.selectedSubjectID
            ?? session.state.selectedSubject?.id
        else {
            return nil
        }

        session.removeSubject(id: selectedSubjectID)
        return session.state.selectedSubject
    }
}
#endif
