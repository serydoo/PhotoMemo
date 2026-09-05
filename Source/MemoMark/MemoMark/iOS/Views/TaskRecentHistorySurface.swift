#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit

/// Presentation of completed task history and the optional history sheet.
///
/// The parent page supplies immutable history rows and remains the owner of
/// queue projection and Photos navigation. This surface only groups rows for
/// display and returns a selected Photo Library link through its callback.
struct TaskRecentHistorySurface: View {

    let rows: [TaskHistoryRowPresentation]
    let onOpenPhotoLibrary: (TaskPhotoLibraryLink) -> Void

    @Binding
    var isSheetPresented: Bool

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(interfaceLanguage.localized(
                        key: "task.recent.title",
                        fallback: "最近保存"
                    ))
                    .font(.headline.weight(.semibold))

                    Text(interfaceLanguage.localized(
                        key: "task.recent.subtitle",
                        fallback: "最近完成的回忆会在这里出现。"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if rows.count > inlineRows.count {
                    ConfigurationCardHeaderIconButton(
                        systemImage: "ellipsis",
                        accessibilityLabel: interfaceLanguage.localized(
                            key: "task.recent.more",
                            fallback: "查看更多最近保存的回忆"
                        )
                    ) {
                        isSheetPresented = true
                    }
                }
            }
            .padding(.horizontal, 4)

            if rows.isEmpty {
                emptyState
            } else {
                groupedHistory
            }
        }
        .sheet(isPresented: $isSheetPresented) {
            historySheet
        }
    }

    private var inlineRows: [TaskHistoryRowPresentation] {
        Array(rows.prefix(4))
    }

    private var groupedHistory: some View {
        VStack(spacing: 0) {
            ForEach(Array(groupedRows.enumerated()), id: \.element.id) { index, group in
                groupHeader(title: group.title, isFirst: index == 0)

                ForEach(group.rows) { row in
                    historyRow(row)

                    if row.id != group.rows.last?.id {
                        HorizontalDivider(
                            horizontalInset:
                                CompactInformationRowMetrics.horizontalPadding
                        )
                    }
                }
            }
        }
        .v1CardChrome()
    }

    private var groupedRows: [TaskHistoryGroup] {
        let calendar = Calendar.autoupdatingCurrent
        let rowsByDay = Dictionary(grouping: inlineRows) { row in
            calendar.startOfDay(for: row.timestamp)
        }

        return rowsByDay.keys.sorted(by: >).map { date in
            TaskHistoryGroup(
                id: date,
                title: historyGroupTitle(for: date),
                rows: rowsByDay[date] ?? []
            )
        }
    }

    private func groupHeader(title: String, isFirst: Bool) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Rectangle()
                .fill(ConfigurationUI.faintHairline)
                .frame(height: 1)
        }
        .padding(.horizontal, 12)
        .padding(.top, isFirst ? 12 : 16)
        .padding(.bottom, 4)
    }

    private func historyGroupTitle(for date: Date) -> String {
        let calendar = Calendar.autoupdatingCurrent

        if calendar.isDateInToday(date) {
            return interfaceLanguage.localized(
                key: "task.history.today",
                fallback: "今天"
            )
        }
        if calendar.isDateInYesterday(date) {
            return interfaceLanguage.localized(
                key: "task.history.yesterday",
                fallback: "昨天"
            )
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = interfaceLanguage.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private var historySheet: some View {
        NavigationStack {
            List(rows) { row in
                historyRow(row)
                    .listRowSeparator(.visible)
            }
            .listStyle(.plain)
            .navigationTitle(interfaceLanguage.localized(
                key: "task.recent.sheet.title",
                fallback: "最近保存的回忆"
            ))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(interfaceLanguage.localized(
                        key: "common.done",
                        fallback: "完成"
                    )) {
                        isSheetPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .memoMarkSheet(.browser)
    }

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.badge.questionmark")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(ConfigurationUI.controlBackground))

            VStack(alignment: .leading, spacing: 3) {
                Text(interfaceLanguage.localized(
                    key: "task.recent.empty.title",
                    fallback: "还没有保存的回忆"
                ))
                .font(.subheadline.weight(.semibold))

                Text(interfaceLanguage.localized(
                    key: "task.recent.empty.detail",
                    fallback: "从 Apple Photos 分享照片后，这里会显示最近保存的回忆。"
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .v1CardChrome()
    }

    @ViewBuilder
    private func historyRow(_ row: TaskHistoryRowPresentation) -> some View {
        if let link = row.photoLibraryLink {
            Button {
                onOpenPhotoLibrary(link)
            } label: {
                historyRowContent(row)
            }
            .buttonStyle(.plain)
        } else {
            historyRowContent(row)
        }
    }

    private func historyRowContent(_ row: TaskHistoryRowPresentation) -> some View {
        HStack(spacing: 10) {
            TaskLocalThumbnail(
                sourceURL: row.previewSourceURL,
                symbolName: row.symbolName,
                tint: row.tint,
                size: CGSize(width: 56, height: 48),
                itemCount: row.totalCount
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(row.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(row.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Label(UserFacingDateFormatter.dateTime(row.timestamp), systemImage: "clock")
                    Label(row.statusText, systemImage: row.symbolName)
                        .foregroundStyle(row.tint.color)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 70)
        .accessibilityElement(children: .combine)
    }
}

private struct TaskHistoryGroup: Identifiable {
    let id: Date
    let title: String
    let rows: [TaskHistoryRowPresentation]
}
#endif
