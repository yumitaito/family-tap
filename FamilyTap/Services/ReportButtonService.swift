//
//  ReportButtonService.swift
//  FamilyTap
//
//  CRUD for `report_buttons` (spec section 9/13/14). Unlike Family
//  creation (Phase 6), no RPC indirection is needed here: creating or
//  editing a button always happens from within a family the caller is
//  already a member of, so `report_buttons_select_member`'s
//  `is_family_member` check is already satisfied — a plain
//  `INSERT/UPDATE ... RETURNING` works.
//
//  NOTE: `created_by` must be passed explicitly on insert. Leaving it out
//  sends NULL, and `created_by = auth.uid()` in the INSERT policy's WITH
//  CHECK evaluates to NULL (not true) for a NULL column, so the insert is
//  silently rejected by RLS rather than defaulting to the caller.
//

import Foundation
import Supabase

final class ReportButtonService {
    static let shared = ReportButtonService()

    private var client: SupabaseClient { SupabaseService.shared.client }

    private init() {}

    /// Active buttons for a family, in their configured display order.
    func fetchActiveButtons(familyId: UUID) async throws -> [ReportButton] {
        try await client
            .from("report_buttons")
            .select()
            .eq("family_id", value: familyId)
            .eq("is_active", value: true)
            .order("sort_order", ascending: true)
            .execute()
            .value
    }

    /// Creates a button (spec section 13, BUTTON-001).
    func createButton(
        familyId: UUID,
        label: String,
        icon: String?,
        type: ReportButtonType,
        createdBy: UUID
    ) async throws -> ReportButton {
        struct NewReportButton: Encodable {
            let family_id: UUID
            let label: String
            let icon: String?
            let type: String
            let created_by: UUID
        }

        return try await client
            .from("report_buttons")
            .insert(NewReportButton(
                family_id: familyId,
                label: label,
                icon: icon,
                type: type.rawValue,
                created_by: createdBy
            ))
            .select()
            .single()
            .execute()
            .value
    }

    /// Edits a button (spec section 14, BUTTON-002).
    func updateButton(
        id: UUID,
        label: String,
        icon: String?,
        type: ReportButtonType,
        sortOrder: Int
    ) async throws -> ReportButton {
        struct UpdatedReportButton: Encodable {
            let label: String
            let icon: String?
            let type: String
            let sort_order: Int
        }

        return try await client
            .from("report_buttons")
            .update(UpdatedReportButton(label: label, icon: icon, type: type.rawValue, sort_order: sortOrder))
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }

    /// "Deletes" a button (spec section 14) — actually a soft delete
    /// (`is_active = false`), not a row DELETE.
    ///
    /// `reports.button_id` has `ON DELETE CASCADE` (see the Phase 3
    /// migration), so a real DELETE here would silently wipe every report
    /// ever made on this button — directly contradicting spec section 10 /
    /// 37's "報告履歴自体は削除しない" (history is never deleted). Setting
    /// `is_active = false` instead removes it from
    /// `fetchActiveButtons`/HomeView (identical effect for the user) while
    /// keeping the row so History (Phase 11) can still join against it.
    func deleteButton(id: UUID) async throws {
        struct Deactivate: Encodable {
            let is_active = false
        }

        try await client
            .from("report_buttons")
            .update(Deactivate())
            .eq("id", value: id)
            .execute()
    }
}
