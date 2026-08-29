//
//  Family.swift
//  FamilyTap
//
//  Maps to the `families` table (spec section 24).
//

import Foundation

struct Family: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var inviteCode: String
    let createdBy: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case inviteCode = "invite_code"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}
