//
//  DailyStatusCard.swift
//  FamilyTap
//
//  Row for one DAILY-type button in HOME-001's「今日の状態」section (spec
//  section 8/10/40). Tapping reports it, same as ReportButtonCard —
//  HomeView decides whether to confirm first (spec section 33) when it's
//  already been reported today. Long-press opens edit (BUTTON-002), same
//  as ReportButtonCard.
//

import SwiftUI

struct DailyStatusCard: View {
    let button: ReportButton
    let status: DailyReportStatus?
    var isReporting: Bool = false
    var onTap: () -> Void = {}
    var onLongPress: () -> Void = {}

    var body: some View {
        HStack(spacing: 16) {
            Text(button.icon ?? "📌")
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 4) {
                Text(button.label)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let status {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(JapanCalendar.timeString(from: status.reportedAt))
                        Text(status.reporterName)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "minus.circle.fill")
                        Text("未報告")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isReporting {
                ProgressView()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(isReporting ? 0.6 : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isReporting else { return }
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        DailyStatusCard(
            button: ReportButton(
                id: UUID(), familyId: UUID(), label: "犬に朝ごはんあげた", icon: "🐶",
                type: .daily, sortOrder: 0, isActive: true, createdBy: nil, createdAt: .now, updatedAt: .now
            ),
            status: DailyReportStatus(reportedAt: .now, reporterName: "お父さん")
        )
        DailyStatusCard(
            button: ReportButton(
                id: UUID(), familyId: UUID(), label: "犬に夜ごはんあげた", icon: "🌙",
                type: .daily, sortOrder: 1, isActive: true, createdBy: nil, createdAt: .now, updatedAt: .now
            ),
            status: nil
        )
    }
    .padding()
}
