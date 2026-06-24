#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct MemorySubjectEditorView: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            if let subject = session.state.selectedSubject {
                InspectorSectionView(
                    "Overview",
                    systemImage: "person.fill"
                ) {
                    InspectorPropertyRow(
                        title: "Identity",
                        value: subject.identity.displayName,
                        systemImage: "person.text.rectangle"
                    )
                    InspectorPropertyRow(
                        title: "Relationship",
                        value: subject.relationship.label,
                        systemImage: "person.2.fill"
                    )
                    InspectorPropertyRow(
                        title: "Reference Date",
                        value:
                            subject.referenceDate.formatted(
                                date: .abbreviated,
                                time: .omitted
                            ),
                        systemImage: "calendar"
                    )
                }

                InspectorSectionView(
                    "Behavior",
                    systemImage: "switch.2"
                ) {
                    InspectorPropertyRow(
                        title: "Primary Anchor",
                        value: subject.behavior.primaryAnchor,
                        systemImage: "flag.fill"
                    )
                    InspectorPropertyRow(
                        title: "Icon Strategy",
                        value: subject.behavior.iconStrategy.rawValue,
                        systemImage: "person.crop.circle.fill"
                    )
                    InspectorPropertyRow(
                        title: "Badge Strategy",
                        value: subject.behavior.badgeStrategy.rawValue,
                        systemImage: "camera.fill"
                    )
                }
            }
        }
    }
}
#endif
