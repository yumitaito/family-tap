//
//  HistoryRow.swift
//  FamilyTap
//
//  One row in HISTORY-001 (spec section 15): icon, button name, reporter,
//  time.
//

import SwiftUI

struct HistoryRow: View {
    let entry: HistoryEntry

    var body: some View {
        HStack(spacing: 12) {
            Text(entry.buttonIcon ?? "📌")
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.buttonLabel)
                    .font(.body)
                Text(entry.reporterName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(JapanCalendar.timeString(from: entry.createdAt))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        HistoryRow(
            entry: HistoryEntry(
                id: UUID(),
                createdAt: .now,
                reporterId: UUID(),
                reporterName: "お父さん",
                buttonLabel: "犬に朝ごはんあげた",
                buttonIcon: "🐶"
            )
        )
    }
}
