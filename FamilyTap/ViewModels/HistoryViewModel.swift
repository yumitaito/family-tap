//
//  HistoryViewModel.swift
//  FamilyTap
//
//  Backs HistoryView (HISTORY-001, spec section 15), kept live via
//  Realtime (spec section 36), plus 取り消し (cancel) of the current
//  user's own reports.
//

import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var entries: [HistoryEntry] = []
    @Published private(set) var isLoading = true
    @Published var errorMessage: String?

    /// So HistoryView can only offer 「取り消し」 on the current user's own
    /// entries — cancelling is individually managed, not a shared family
    /// action.
    @Published private(set) var currentUserId: UUID?

    private let realtime = RealtimeReportsService()
    private var realtimeFamilyID: UUID?

    /// `entries` split into day-labeled sections ("今日" / "昨日" / ...),
    /// in the same newest-first order the entries already come in — since
    /// `entries` is sorted by created_at desc, same-label rows are always
    /// contiguous, so a single linear pass is enough (no need to re-sort
    /// group keys afterward).
    var groupedEntries: [(label: String, entries: [HistoryEntry])] {
        var groups: [(label: String, entries: [HistoryEntry])] = []
        for entry in entries {
            let label = JapanCalendar.dayLabel(for: entry.createdAt)
            if groups.indices.last.map({ groups[$0].label == label }) == true {
                groups[groups.count - 1].entries.append(entry)
            } else {
                groups.append((label, [entry]))
            }
        }
        return groups
    }

    func load(familyId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            entries = try await ReportService.shared.fetchHistory(familyId: familyId)
            errorMessage = nil
        } catch {
            errorMessage = "履歴を取得できませんでした。"
        }

        currentUserId = try? await AuthService.shared.currentUserId()

        await startRealtimeIfNeeded(familyId: familyId)
    }

    /// Cancels `entry` (spec-driven addition: long-press → 取り消し).
    /// Removes it from `entries` immediately on success rather than
    /// waiting for the Realtime echo or a full reload.
    func cancel(entry: HistoryEntry) async {
        errorMessage = nil
        do {
            try await ReportService.shared.cancelReport(id: entry.id)
            entries.removeAll { $0.id == entry.id }
        } catch {
            errorMessage = "取り消せませんでした。\nもう一度お試しください。"
        }
    }

    private func startRealtimeIfNeeded(familyId: UUID) async {
        guard realtimeFamilyID != familyId else { return }
        realtimeFamilyID = familyId

        await realtime.start(familyId: familyId) { [weak self] in
            Task { await self?.reloadSilently(familyId: familyId) }
        }
    }

    /// Re-fetches history in response to a Realtime change (someone else's
    /// new report, or a cancellation made elsewhere) — deliberately
    /// doesn't touch `isLoading`, since that would flash a spinner over an
    /// already-populated list.
    private func reloadSilently(familyId: UUID) async {
        guard let updated = try? await ReportService.shared.fetchHistory(familyId: familyId) else { return }
        entries = updated
    }
}
