//
//  ReportButtonCard.swift
//  FamilyTap
//
//  Visual card for one report button in the HOME-001 grid (spec section
//  8/40). Tap reports (spec section 11); long-press opens edit
//  (BUTTON-002). Plain gesture modifiers rather than a Button, since
//  Button + onLongPressGesture on the same view fight over which one
//  handles a given touch.
//

import SwiftUI

struct ReportButtonCard: View {
    let button: ReportButton
    var isReporting: Bool = false
    var onTap: () -> Void = {}
    var onLongPress: () -> Void = {}

    var body: some View {
        VStack(spacing: 8) {
            if isReporting {
                ProgressView()
            } else {
                Text(button.icon ?? "📌")
                    .font(.system(size: 32))
            }
            Text(button.label)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 96)
        .padding()
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
    ReportButtonCard(
        button: ReportButton(
            id: UUID(),
            familyId: UUID(),
            label: "犬の散歩に行った",
            icon: "🚶",
            type: .normal,
            sortOrder: 0,
            isActive: true,
            createdBy: nil,
            createdAt: .now,
            updatedAt: .now
        )
    )
    .padding()
}
