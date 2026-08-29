//
//  HomeViewModel.swift
//  FamilyTap
//
//  Backs HomeView (HOME-001): loads the button list, DAILY判定 status for
//  today (spec section 31), handles tap-to-report (spec section 11), and
//  keeps DAILY status live via Realtime (spec section 36).
//

import Foundation

struct DailyReportStatus {
    let reportedAt: Date
    let reporterName: String
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var buttons: [ReportButton] = []
    @Published private(set) var isLoading = true
    @Published var errorMessage: String?

    /// button_id → today's (Asia/Tokyo) first report, for DAILY-type
    /// buttons only. Absence of a key means "未報告".
    @Published private(set) var dailyStatuses: [UUID: DailyReportStatus] = [:]

    /// Buttons currently disabled post-tap (spec section 33: 1〜2秒 disabled
    /// to guard against accidental double-taps). Also covers the network
    /// round-trip itself, since a button stays in this set until both the
    /// request and the minimum cooldown have finished.
    @Published private(set) var reportingButtonIDs: Set<UUID> = []
    @Published var toast: ToastState?

    private let realtime = RealtimeReportsService()
    private var realtimeFamilyID: UUID?

    func load(familyId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            buttons = try await ReportButtonService.shared.fetchActiveButtons(familyId: familyId)
            errorMessage = nil
            await refreshDailyStatuses(familyId: familyId)
        } catch {
            errorMessage = "報告ボタンを取得できませんでした。"
        }

        await startRealtimeIfNeeded(familyId: familyId)
    }

    /// Someone else's report (or our own, echoed back) arriving live —
    /// only DAILY status needs to react (spec section 36).
    private func startRealtimeIfNeeded(familyId: UUID) async {
        guard realtimeFamilyID != familyId else { return }
        realtimeFamilyID = familyId

        await realtime.start(familyId: familyId) { [weak self] in
            guard let self else { return }
            Task { await self.refreshDailyStatuses(familyId: familyId) }
        }
    }

    /// Reports `button`. For a DAILY button that's already been reported
    /// today, HomeView is expected to have already confirmed with the user
    /// (spec section 33: "もう一度報告しますか？") before calling this.
    func report(button: ReportButton, familyId: UUID) async {
        guard !reportingButtonIDs.contains(button.id) else { return }
        reportingButtonIDs.insert(button.id)

        // Keep the button disabled for at least this long even if the
        // network call itself is instant (spec section 33's 1〜2秒 debounce),
        // without adding extra delay on top of a slow request.
        async let cooldown = Task.sleep(nanoseconds: 1_500_000_000)

        do {
            let userId = try await AuthService.shared.currentUserId()
            let report = try await ReportService.shared.createReport(familyId: familyId, buttonId: button.id, userId: userId)
            toast = .success("報告しました ✓")
            if button.type == .daily {
                await refreshDailyStatuses(familyId: familyId)
            }
            // Fire-and-forget (spec section 11 step 6): a push failing must
            // never turn a successful report into an error for the user.
            Task { await PushNotificationService.notifyFamily(reportId: report.id) }
        } catch {
            toast = .failure("報告できませんでした。")
        }

        _ = try? await cooldown
        reportingButtonIDs.remove(button.id)
    }

    private func refreshDailyStatuses(familyId: UUID) async {
        let dailyButtonIDs = buttons.filter { $0.type == .daily }.map(\.id)
        guard !dailyButtonIDs.isEmpty else {
            dailyStatuses = [:]
            return
        }

        do {
            let todaysReports = try await ReportService.shared.fetchTodayReports(
                familyId: familyId,
                buttonIds: dailyButtonIDs,
                range: JapanCalendar.todayRange()
            )
            var statuses: [UUID: DailyReportStatus] = [:]
            for entry in todaysReports where statuses[entry.buttonId] == nil {
                // `todaysReports` is oldest-first, so the first entry we see
                // per button is who reported it first today.
                statuses[entry.buttonId] = DailyReportStatus(reportedAt: entry.createdAt, reporterName: entry.reporterName)
            }
            dailyStatuses = statuses
        } catch {
            // Non-fatal: leave whatever statuses we already had. Worst case
            // "今日の状態" is briefly stale rather than the whole screen
            // failing over a status refresh.
        }
    }
}
