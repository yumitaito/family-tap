//
//  ProfileService.swift
//  FamilyTap
//
//  Lookup + edit of a single `profiles` row — used by SettingsView to show
//  and change the signed-in user's own 表示名 (spec section 44).
//

import Foundation
import Supabase

final class ProfileService {
    static let shared = ProfileService()

    private var client: SupabaseClient { SupabaseService.shared.client }

    private init() {}

    func fetchProfile(userId: UUID) async throws -> Profile {
        try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
    }

    /// `profiles_update_own` (Phase 4) only allows a user to update their
    /// own row, so this is always self-service — no owner/role gating like
    /// `FamilyService.updateFamilyName` needs.
    func updateDisplayName(userId: UUID, displayName: String) async throws {
        struct UpdateProfile: Encodable {
            let display_name: String
        }

        try await client
            .from("profiles")
            .update(UpdateProfile(display_name: displayName))
            .eq("id", value: userId)
            .execute()
    }
}
