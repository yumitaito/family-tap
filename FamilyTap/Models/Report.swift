//
//  Report.swift
//  FamilyTap
//
//  Maps to the `reports` table (spec section 27/39) — an append-only log
//  of "who tapped which button when". The row itself is never deleted
//  (spec section 10: "DB上の報告履歴自体は削除しない"); `cancelledAt`
//  being non-nil is how a self-service "取り消し" (cancel, from History)
//  is represented instead — see `ReportService.cancelReport`.
//

import Foundation

struct Report: Identifiable, Codable, Hashable {
    let id: UUID
    let familyId: UUID
    let buttonId: UUID
    let userId: UUID
    let createdAt: Date
    var cancelledAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case buttonId = "button_id"
        case userId = "user_id"
        case createdAt = "created_at"
        case cancelledAt = "cancelled_at"
    }
}
