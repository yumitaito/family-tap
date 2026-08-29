//
//  FamilyStore.swift
//  FamilyTap
//
//  Current-user's family-membership state, analogous to SessionStore for
//  auth. RootView reads this (once signed in) to decide between the
//  家族を作る/参加する gate and the main app (spec section 6).
//
//  No Realtime yet (that's Phase 12), so callers must call refresh()
//  explicitly after creating/joining a family.
//

import Foundation

@MainActor
final class FamilyStore: ObservableObject {
    @Published private(set) var family: Family?
    @Published private(set) var isLoading = true
    @Published var errorMessage: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let userId = try await AuthService.shared.currentUserId()
            family = try await FamilyService.shared.fetchCurrentFamily(userId: userId)
            errorMessage = nil
        } catch {
            errorMessage = "家族情報を取得できませんでした。"
        }
    }
}
