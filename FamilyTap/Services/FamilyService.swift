//
//  FamilyService.swift
//  FamilyTap
//
//  Family creation / joining / membership lookups (spec sections 16-19).
//  RLS (Phase 4 migration) is what actually enforces "you can only see
//  families/members you belong to" — this layer just shapes the queries.
//

import Foundation
import Supabase

enum FamilyServiceError: Error {
    case inviteCodeNotFound
    case notOwner
}

final class FamilyService {
    static let shared = FamilyService()

    private var client: SupabaseClient { SupabaseService.shared.client }

    private init() {}

    /// The family the given user currently belongs to, if any. A user has
    /// at most one row in `family_members` in this MVP (spec section 16:
    /// "アプリ内ではユーザーは1つのfamilyに所属する").
    func fetchCurrentFamily(userId: UUID) async throws -> Family? {
        struct MembershipRow: Decodable {
            let family: Family
        }

        let rows: [MembershipRow] = try await client
            .from("family_members")
            .select("family:families(*)")
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value

        return rows.first?.family
    }

    /// Creates a family and adds the caller as its 'owner' member (spec
    /// section 17). Both inserts, plus a unique invite code, happen
    /// server-side in one `create_family` SQL function (SECURITY DEFINER),
    /// because a plain client-side "insert family, then insert membership"
    /// can't work under RLS: `INSERT ... RETURNING` on `families` requires
    /// the new row to already pass its own SELECT policy
    /// (`is_family_member`), which isn't true yet at that point — the
    /// membership row is the *next* statement. Bundling them into one
    /// function sidesteps the ordering problem entirely.
    func createFamily(name: String) async throws -> Family {
        try await client
            .rpc("create_family", params: ["family_name": name])
            .execute()
            .value
    }

    /// Redeems an invite code and adds the caller as a 'member' (spec
    /// section 18), via the `join_family` SQL function. This also has to
    /// be server-side: looking up a family by invite code needs a SELECT
    /// on `families`, but `families_select_member` only allows that once
    /// you're already a member — exactly what redeeming a code is meant to
    /// grant. A SECURITY DEFINER function keyed on the exact code you pass
    /// in (rather than a general table SELECT) is also the safer shape:
    /// it can't be used to browse/enumerate other families.
    func joinFamily(inviteCode: String) async throws -> Family {
        do {
            return try await client
                .rpc("join_family", params: ["invite_code_input": inviteCode])
                .execute()
                .value
        } catch {
            if String(describing: error).contains("invite_code_not_found") {
                throw FamilyServiceError.inviteCodeNotFound
            }
            throw error
        }
    }

    /// Renames a family. `families_update_owner` (Phase 4) only allows the
    /// family's `owner` to do this — a `member` calling it matches zero
    /// rows under RLS rather than erroring, so `.select().single()` is what
    /// turns that into a decode failure we can map to `.notOwner` below.
    func updateFamilyName(familyId: UUID, name: String) async throws {
        struct UpdateFamily: Encodable {
            let name: String
        }

        do {
            let _: Family = try await client
                .from("families")
                .update(UpdateFamily(name: name))
                .eq("id", value: familyId)
                .select()
                .single()
                .execute()
                .value
        } catch {
            throw FamilyServiceError.notOwner
        }
    }

    /// All members of a family with their display names, oldest first
    /// (spec section 19, FAMILY-004).
    func fetchMembers(familyId: UUID) async throws -> [FamilyMemberWithProfile] {
        try await client
            .from("family_members")
            .select("id, role, joined_at, profile:profiles(id, display_name)")
            .eq("family_id", value: familyId)
            .order("joined_at", ascending: true)
            .execute()
            .value
    }
}
