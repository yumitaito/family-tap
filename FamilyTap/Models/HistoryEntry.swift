//
//  HistoryEntry.swift
//  FamilyTap
//
//  Decodes a `reports` row joined with its button's label/icon and its
//  reporter's id/display name, for HISTORY-001 (spec section 15).
//
//  `reporterId` exists so HistoryView can show the「取り消し」(cancel)
//  long-press only on the current user's own entries — cancelling a
//  report is individually managed, not a shared family action (unlike
//  editing a DAILY card, which any member can do).
//

import Foundation

struct HistoryEntry: Identifiable, Decodable {
    let id: UUID
    let createdAt: Date
    let reporterId: UUID
    let reporterName: String
    let buttonLabel: String
    let buttonIcon: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case reporter
        case button
    }

    private struct Reporter: Decodable {
        let id: UUID
        let displayName: String
        enum CodingKeys: String, CodingKey {
            case id
            case displayName = "display_name"
        }
    }

    private struct ButtonInfo: Decodable {
        let label: String
        let icon: String?
    }

    // Explicit memberwise init — defining `init(from:)` below suppresses
    // Swift's automatic one, but previews/tests still want to construct
    // these directly without a JSON round-trip.
    init(id: UUID, createdAt: Date, reporterId: UUID, reporterName: String, buttonLabel: String, buttonIcon: String?) {
        self.id = id
        self.createdAt = createdAt
        self.reporterId = reporterId
        self.reporterName = reporterName
        self.buttonLabel = buttonLabel
        self.buttonIcon = buttonIcon
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        let reporter = try container.decode(Reporter.self, forKey: .reporter)
        reporterId = reporter.id
        reporterName = reporter.displayName
        let buttonInfo = try container.decode(ButtonInfo.self, forKey: .button)
        buttonLabel = buttonInfo.label
        buttonIcon = buttonInfo.icon
    }
}
