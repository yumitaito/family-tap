//
//  Profile.swift
//  FamilyTap
//
//  Maps to the `profiles` table (spec section 23). The row itself is
//  created server-side by the `handle_new_user` DB trigger (see Phase 5
//  migrations); this type is only for reading it back.
//

import Foundation

struct Profile: Identifiable, Codable, Equatable {
    let id: UUID
    var displayName: String
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
