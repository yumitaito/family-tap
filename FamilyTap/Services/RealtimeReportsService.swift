//
//  RealtimeReportsService.swift
//  FamilyTap
//
//  Listens for changes to `reports` rows for a family via Supabase
//  Realtime (spec section 36), so a report — or a cancellation of one,
//  see `ReportService.cancelReport` — made on one screen/device shows up
//  on another without a manual pull-to-refresh. HomeView refreshes DAILY
//  status, HistoryView refreshes the list.
//
//  Listens to ANY change type (insert/update/delete), not just INSERT:
//  cancelling a report is an UPDATE (`cancelled_at` gets set, the row
//  itself is never deleted — spec section 10/37), and HomeView's DAILY
//  card needs to un-check itself when that happens, even if the
//  cancellation was made from HistoryView in a different tab.
//
//  Requires `reports` to be added to the `supabase_realtime` publication
//  (see the Phase 12 migration) — RLS (`reports_select_member`) still
//  governs which rows each subscriber actually receives.
//

import Foundation
import Supabase

@MainActor
final class RealtimeReportsService {
    private var client: SupabaseClient { SupabaseService.shared.client }
    private var channel: RealtimeChannelV2?
    private var listenTask: Task<Void, Never>?

    /// Starts listening for changes to `reports` scoped to `familyId`,
    /// calling `onChange` for each one. Callers just refetch on this
    /// signal rather than trying to apply the raw payload themselves.
    /// Calling this again (e.g. with a different family) tears down any
    /// previous subscription first.
    func start(familyId: UUID, onChange: @escaping @MainActor () -> Void) async {
        await stop()

        let channel = client.channel("reports-changes-\(familyId.uuidString)")
        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "reports",
            filter: .eq("family_id", value: familyId)
        )

        listenTask = Task {
            for await _ in changes {
                onChange()
            }
        }

        await channel.subscribe()
        self.channel = channel
    }

    func stop() async {
        listenTask?.cancel()
        listenTask = nil

        if let channel {
            await client.removeChannel(channel)
        }
        channel = nil
    }
}
