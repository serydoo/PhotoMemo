#if !MEMOMARK_SHARE_EXTENSION
import Foundation

enum SubjectLibraryFactory {

    static func makeFirstRunSubject(
        name: String,
        birthday: Date,
        language: MemoMarkLanguage = .interfaceStored
    ) -> MemorySubject {
        let trimmedName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let resolvedName = trimmedName.isEmpty
            ? language.localized(key: "subject.default.first_name", fallback: "记忆主角")
            : trimmedName
        let birthdayAnchor = MemorySubject.TimeAnchor(
            title: language.localized(key: "生日", fallback: "生日"),
            date: birthday,
            note: language.localized(key: "subject.default.birthday_note", fallback: "用来回顾照片拍摄时的年龄。"),
            anchorType: .birthday,
            expressionStyle: .birthdayNatural
        )
        return MemorySubject(
            identity: .init(
                displayName: resolvedName,
                shortName: resolvedName
            ),
            relationship: .init(
                role: "",
                label: ""
            ),
            definition: language.localized(key: "subject.default.first_definition", fallback: "围绕这个主角回顾照片中的时间。"),
            referenceDate: birthday,
            timeAnchors: [birthdayAnchor],
            activeTimeAnchorID: birthdayAnchor.id,
            expressionSubjectSource: .shortName,
            behavior: .init(
                primaryAnchor: birthdayAnchor.title,
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(
                    title: language.localized(key: "生日回顾", fallback: "生日回顾"),
                    blocks: []
                )
            ),
            decorations: []
        )
    }

    static func makeDefaultSubject(
        referenceDate: Date,
        language: MemoMarkLanguage = .interfaceStored
    ) -> MemorySubject {
        let birthdayAnchor =
            MemorySubject.TimeAnchor(
                title: language.localized(key: "生日", fallback: "生日"),
                date: referenceDate,
                note: language.localized(key: "subject.default.anchor_note", fallback: "请补充这个对象最重要的时间锚点。"),
                anchorType: .birthday,
                expressionStyle:
                    .defaultStyle(for: .birthday)
            )
        return MemorySubject(
            identity: .init(
                displayName: language.localized(key: "subject.default.name", fallback: "新的记忆对象"),
                shortName: ""
            ),
            relationship: .init(
                role: language.localized(key: "家人", fallback: "家人"),
                label: language.localized(key: "未设置", fallback: "未设置")
            ),
            definition: language.localized(key: "subject.default.definition", fallback: "在这里补充对象身份、头像与时间锚点。"),
            referenceDate: referenceDate,
            timeAnchors: [birthdayAnchor],
            activeTimeAnchorID: birthdayAnchor.id,
            expressionSubjectSource: .displayName,
            behavior: .init(
                primaryAnchor: birthdayAnchor.title,
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(
                    title: language.localized(key: "生日记忆", fallback: "生日记忆"),
                    blocks: []
                )
            ),
            decorations: []
        )
    }
}

enum SubjectLibraryResolver {

    static func resolvedBootstrapSubject(
        subjects: [MemorySubject]?,
        selectedSubjectID: MemorySubject.ID?,
        fallbackSubject: MemorySubject?
    ) -> MemorySubject? {
        if let subjects {
            let subjects =
                sanitizedSubjectLibrary(subjects)

            guard !subjects.isEmpty else {
                return fallbackSubject
            }

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

        var resolvedSubjects =
            sanitizedSubjectLibrary(subjects)

        guard !isLegacyDemoSubject(selectedSubject) else {
            return resolvedSubjects
        }

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

    static func sanitizedSubjectLibrary(
        _ subjects: [MemorySubject]
    ) -> [MemorySubject] {
        subjects.filter {
            !isLegacyDemoSubject($0)
        }
    }

    private static func isLegacyDemoSubject(
        _ subject: MemorySubject
    ) -> Bool {
        subject.identity.displayName == "Kyoto Spring"
        && subject.identity.shortName == "Kyoto"
    }

    static func persist(
        subjects: [MemorySubject],
        selectedSubjectID: MemorySubject.ID?,
        coordinator: ConfigurationCoordinator?,
        memoryPresets: [MemoryPreset] = [],
        selectedMemoryPresetID: MemoryPreset.ID? = nil
    ) {
        guard let coordinator else {
            return
        }

        _ =
            coordinator
            .saveSubjectLibrary(
                subjects:
                    sanitizedSubjectLibrary(subjects),
                selectedSubjectID:
                    selectedSubjectID,
                memoryPresets:
                    memoryPresets,
                selectedMemoryPresetID:
                    selectedMemoryPresetID
            )
    }
}

@MainActor
enum SubjectLibraryMutationCoordinator {

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
            SubjectLibraryFactory
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
