import SwiftUI

struct BadgePickerView: View {

    let badges: [Badge]

    let selectedBadge: Badge?

    let onSelect: (Badge) -> Void

    var body: some View {

        List {

            ForEach(badges) { badge in

                Button {

                    onSelect(badge)

                } label: {

                    HStack(spacing: 12) {

                        badgeIcon(
                            badge
                        )

                        VStack(
                            alignment: .leading
                        ) {

                            Text(
                                badge.name
                            )

                            Text(
                                badge.type.displayName
                            )
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )
                        }

                        Spacer()

                        if badge.id ==
                            selectedBadge?.id {

                            Image(
                                systemName: "checkmark.circle.fill"
                            )
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(
            "Badge"
        )
    }

    @ViewBuilder
    private func badgeIcon(
        _ badge: Badge
    ) -> some View {

        switch badge.type {

        case .none:

            Image(
                systemName: "circle"
            )

        case .systemSymbol:

            Image(
                systemName:
                    badge.systemSymbol
                    ?? "questionmark"
            )

        case .png,
             .customUpload,
             .svg:

            Image(
                systemName: "photo"
            )
        }
    }
}
