//
//  EditFamilyNameViewModel.swift
//  FamilyTap
//
//  Backs EditFamilyNameView (spec section 44's 家族 row). Renaming is
//  owner-only (`families_update_owner`, Phase 4) — a non-owner sees a
//  specific error rather than a generic failure.
//

import Foundation

@MainActor
final class EditFamilyNameViewModel: ObservableObject {
    @Published var name: String
    @Published var isLoading = false
    @Published var errorMessage: String?

    init(currentName: String) {
        name = currentName
    }

    func save(familyId: UUID) async -> Bool {
        errorMessage = nil
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "家族名を入力してください。"
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await FamilyService.shared.updateFamilyName(familyId: familyId, name: trimmed)
            return true
        } catch FamilyServiceError.notOwner {
            errorMessage = "家族名の変更はオーナーのみ行えます。"
            return false
        } catch {
            errorMessage = "家族名を変更できませんでした。\nもう一度お試しください。"
            return false
        }
    }
}
