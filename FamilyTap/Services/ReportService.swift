//
//  ReportService.swift
//  FamilyTap
//
//  Creates report rows (spec section 11 steps 1-3), looks up today's
//  reports for DAILY判定 (spec section 31), fetches history (spec section
//  15), and cancels a report (long-press from History). No bootstrapping
//  problem here like family creation had (Phase 6): the caller is always
//  already a member of the family they're reporting into, so
//  `reports_select_member`'s `is_family_member` check is already
//  satisfied for `INSERT...RETURNING` and for plain SELECTs.
//

import Foundation
import Supabase

final class ReportService {
    static let shared = ReportService()

    private var client: SupabaseClient { SupabaseService.shared.client }

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private init() {}

    @discardableResult
    func createReport(familyId: UUID, buttonId: UUID, userId: UUID) async throws -> Report {
        struct NewReport: Encodable {
            let family_id: UUID
            let button_id: UUID
            let user_id: UUID
        }

        return try await client
            .from("reports")
            .insert(NewReport(family_id: familyId, button_id: buttonId, user_id: userId))
            .select()
            .single()
            .execute()
            .value
    }

    /// "Cancels" a report (取り消し, long-pressed from History) — actually
    /// a soft cancel (`cancelled_at = now()`), not a row DELETE. See the
    /// migration that added this column for why. `reports_cancel_own`
    /// (added alongside it) means this silently matches zero rows if the
    /// caller isn't the original reporter; HistoryView is expected to only
    /// offer this action on the current user's own entries in the first
    /// place (spec-driven: cancelling is individually managed, unlike
    /// editing a shared DAILY card).
    func cancelReport(id: UUID) async throws {
        struct CancelReport: Encodable {
            let cancelled_at: String
        }

        try await client
            .from("reports")
            .update(CancelReport(cancelled_at: Self.iso8601Formatter.string(from: Date())))
            .eq("id", value: id)
            .execute()
    }

    /// One row per report made today (Asia/Tokyo) for the given buttons,
    /// oldest first — so "first entry per button_id" is "who reported it
    /// first today" (spec section 31's existence check, plus who/when for
    /// display). Excludes cancelled reports, so cancelling the only report
    /// for a DAILY button today correctly flips it back to "未報告".
    func fetchTodayReports(familyId: UUID, buttonIds: [UUID], range: (start: Date, end: Date)) async throws -> [TodayReportEntry] {
        guard !buttonIds.isEmpty else { return [] }

        return try await client
            .from("reports")
            .select("button_id, created_at, reporter:profiles(display_name)")
            .eq("family_id", value: familyId)
            .in("button_id", values: buttonIds)
            .gte("created_at", value: Self.iso8601Formatter.string(from: range.start))
            .lt("created_at", value: Self.iso8601Formatter.string(from: range.end))
            .is("cancelled_at", value: nil)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    /// The family's full report history, newest first (spec section 15,
    /// HISTORY-001). Excludes cancelled reports — cancelling one removes
    /// it from History (spec-driven addition; the underlying row still
    /// exists, see `cancelReport`). `report_buttons` is joined even for
    /// deactivated buttons (soft-deleted, see
    /// `ReportButtonService.deleteButton`), so old history entries keep
    /// their label/icon.
    func fetchHistory(familyId: UUID, limit: Int = 200) async throws -> [HistoryEntry] {
        try await client
            .from("reports")
            .select("id, created_at, reporter:profiles(id, display_name), button:report_buttons(label, icon)")
            .eq("family_id", value: familyId)
            .is("cancelled_at", value: nil)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }
}

/// Decodes a `reports` row joined with the reporter's `profiles.display_name`.
struct TodayReportEntry: Decodable {
    let buttonId: UUID
    let createdAt: Date
    let reporterName: String

    private enum CodingKeys: String, CodingKey {
        case buttonId = "button_id"
        case createdAt = "created_at"
        case reporter
    }

    private struct Reporter: Decodable {
        let displayName: String
        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        buttonId = try container.decode(UUID.self, forKey: .buttonId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        reporterName = try container.decode(Reporter.self, forKey: .reporter).displayName
    }
}
