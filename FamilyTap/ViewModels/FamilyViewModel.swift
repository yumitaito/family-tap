//
//  FamilyViewModel.swift
//  FamilyTap
//
//  Backs CreateFamilyView (FAMILY-002) and JoinFamilyView (FAMILY-003).
//

import Foundation

@MainActor
final class FamilyViewModel: ObservableObject {
    @Published var familyName = ""
    @Published var inviteCodeInput = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var createdFamily: Family?

    func createFamily() async {
        errorMessage = nil
        let trimmedName = familyName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "家族名を入力してください。"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            createdFamily = try await FamilyService.shared.createFamily(name: trimmedName)
        } catch {
            errorMessage = "家族を作成できませんでした。\nもう一度お試しください。"
        }
    }

    @discardableResult
    func joinFamily() async -> Bool {
        errorMessage = nil
        let code = inviteCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else {
            errorMessage = "招待コードを入力してください。"
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await FamilyService.shared.joinFamily(inviteCode: code)
            return true
        } catch FamilyServiceError.inviteCodeNotFound {
            errorMessage = "招待コードが見つかりません。"
            return false
        } catch {
            errorMessage = "参加できませんでした。\nもう一度お試しください。"
            return false
        }
    }
}
