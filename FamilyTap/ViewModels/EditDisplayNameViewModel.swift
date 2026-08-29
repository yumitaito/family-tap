//
//  EditDisplayNameViewModel.swift
//  FamilyTap
//
//  Backs EditDisplayNameView (spec section 44's 表示名 row).
//

import Foundation

@MainActor
final class EditDisplayNameViewModel: ObservableObject {
    @Published var displayName: String
    @Published var isLoading = false
    @Published var errorMessage: String?

    init(currentName: String) {
        displayName = currentName
    }

    func save() async -> Bool {
        errorMessage = nil
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "表示名を入力してください。"
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let userId = try await AuthService.shared.currentUserId()
            try await ProfileService.shared.updateDisplayName(userId: userId, displayName: trimmed)
            return true
        } catch {
            errorMessage = "表示名を変更できませんでした。\nもう一度お試しください。"
            return false
        }
    }
}
