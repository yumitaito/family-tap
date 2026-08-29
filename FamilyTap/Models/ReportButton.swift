//
//  ReportButton.swift
//  FamilyTap
//
//  Maps to the `report_buttons` table (spec section 26/39).
//

import Foundation

enum ReportButtonType: String, Codable {
    case normal
    case daily
}

struct ReportButton: Identifiable, Codable, Hashable {
    let id: UUID
    let familyId: UUID
    var label: String
    var icon: String?
    var type: ReportButtonType
    var sortOrder: Int
    var isActive: Bool
    let createdBy: UUID?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case label
        case icon
        case type
        case sortOrder = "sort_order"
        case isActive = "is_active"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
