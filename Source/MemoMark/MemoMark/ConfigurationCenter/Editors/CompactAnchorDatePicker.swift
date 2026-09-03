#if !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct CompactAnchorDatePicker: View {

    @Binding var selection: Date

    private static let wheelHeight: CGFloat = 144
    private let calendar = Calendar(identifier: .gregorian)
    private let years = Array(1900...2100)

    private var selectedYear: Int {
        calendar.component(.year, from: selection)
    }

    private var selectedMonth: Int {
        calendar.component(.month, from: selection)
    }

    private var selectedDay: Int {
        calendar.component(.day, from: selection)
    }

    private var availableDays: ClosedRange<Int> {
        let components = DateComponents(
            year: selectedYear,
            month: selectedMonth
        )
        guard
            let monthDate = calendar.date(from: components),
            let range = calendar.range(of: .day, in: .month, for: monthDate)
        else {
            return 1...31
        }
        return range.lowerBound...range.upperBound
    }

    var body: some View {
#if os(iOS)
        HStack(spacing: 2) {
            compactWheel(values: years, selection: selectedYear, suffix: "年") {
                update(year: $0)
            }
            .frame(maxWidth: .infinity)

            compactWheel(values: Array(1...12), selection: selectedMonth, suffix: "月") {
                update(month: $0)
            }
            .frame(width: 84)

            compactWheel(
                values: Array(availableDays),
                selection: min(selectedDay, availableDays.upperBound),
                suffix: "日"
            ) {
                update(day: $0)
            }
            .frame(width: 84)
        }
        .frame(height: Self.wheelHeight)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(
            MemoMarkLanguage.interfaceStored.localized(
                key: "accessibility.anchor_date",
                fallback: "Anchor date"
            )
        ))
#else
        DatePicker(
            "日期",
            selection: $selection,
            displayedComponents: .date
        )
#endif
    }

#if os(iOS)
    private func compactWheel(
        values: [Int],
        selection: Int,
        suffix: String,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        Picker(
            suffix,
            selection: Binding(
                get: { selection },
                set: onChange
            )
        ) {
            ForEach(values, id: \.self) { value in
                Text("\(value)\(suffix)")
                    .tag(value)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
    }
#endif

    private func update(
        year: Int? = nil,
        month: Int? = nil,
        day: Int? = nil
    ) {
        var components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: selection
        )
        components.year = year ?? selectedYear
        components.month = month ?? selectedMonth

        let requestedDay = day ?? selectedDay
        components.day = 1
        guard let targetMonth = calendar.date(from: components) else {
            return
        }
        let dayRange = calendar.range(
            of: .day,
            in: .month,
            for: targetMonth
        ) ?? 1..<32
        components.day = min(requestedDay, dayRange.count)

        if let date = calendar.date(from: components) {
            selection = date
        }
    }
}

#endif
