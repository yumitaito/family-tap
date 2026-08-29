//
//  FamilyMemberWithProfile.swift
//  FamilyTap
//
//  Result shape for FAMILY-004 (家族メンバー画面, spec section 19/37): a
//  `family_members` row with its `profiles` row embedded via a PostgREST
//  resource embed (`profile:profiles(id, display_name)`), so the member
//  list can show display names in a single query.
//

import Foundation

struct FamilyMemberWithProfile: Identifiable, Decodable {
    let id: UUID
    let role: String
    let joinedAt: Date
    let profile: Profile

    struct Profile: Decodable {
        let id: UUID
        let displayName: String

        enum CodingKeys: String, CodingKey {
            case id
            case displayName = "display_name"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case joinedAt = "joined_at"
        case profile
    }
}
