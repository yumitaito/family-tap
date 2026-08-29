//
//  SettingsViewModel.swift
//  FamilyTap
//
//  Backs SETTINGS-001 (spec section 44): the signed-in user's own display
//  name, plus ログアウト.
//

import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var displayName: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadProfile() async {
        do {
            let userId = try await AuthService.shared.currentUserId()
            displayName = try await ProfileService.shared.fetchProfile(userId: userId).displayName
        } catch {
            // Non-fatal: the row just shows "-" a bit longer than usual;
            // no need to surface a full error banner for this.
        }
    }

    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AuthService.shared.signOut()
        } catch {
            errorMessage = "ログアウトできませんでした。もう一度お試しください。"
        }
    }
}
