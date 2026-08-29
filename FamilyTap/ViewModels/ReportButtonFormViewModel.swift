//
//  ReportButtonFormViewModel.swift
//  FamilyTap
//
//  Backs both CreateReportButtonView (BUTTON-001) and EditReportButtonView
//  (BUTTON-002) — the fields are identical, only which service call fires
//  differs.
//

import Foundation

@MainActor
final class ReportButtonFormViewModel: ObservableObject {
    @Published var label = ""
    @Published var icon: String = ReportButtonIcons.default
    @Published var type: ReportButtonType = .normal
    @Published var sortOrder: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadForEditing(_ button: ReportButton) {
        label = button.label
        icon = button.icon ?? ReportButtonIcons.default
        type = button.type
        sortOrder = button.sortOrder
    }

    func create(familyId: UUID) async -> Bool {
        guard validateLabel() else { return false }

        isLoading = true
        defer { isLoading = false }

        do {
            let userId = try await AuthService.shared.currentUserId()
            _ = try await ReportButtonService.shared.createButton(
                familyId: familyId,
                label: label.trimmingCharacters(in: .whitespacesAndNewlines),
                icon: icon,
                type: type,
                createdBy: userId
            )
            return true
        } catch {
            errorMessage = "作成できませんでした。\nもう一度お試しください。"
            return false
        }
    }

    func update(buttonId: UUID) async -> Bool {
        guard validateLabel() else { return false }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await ReportButtonService.shared.updateButton(
                id: buttonId,
                label: label.trimmingCharacters(in: .whitespacesAndNewlines),
                icon: icon,
                type: type,
                sortOrder: sortOrder
            )
            return true
        } catch {
            errorMessage = "保存できませんでした。\nもう一度お試しください。"
            return false
        }
    }

    func delete(buttonId: UUID) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            try await ReportButtonService.shared.deleteButton(id: buttonId)
            return true
        } catch {
            errorMessage = "削除できませんでした。\nもう一度お試しください。"
            return false
        }
    }

    private func validateLabel() -> Bool {
        errorMessage = nil
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "ボタン名を入力してください。"
            return false
        }
        guard trimmed.count <= 50 else {
            errorMessage = "ボタン名は50文字以内で入力してください。"
            return false
        }
        return true
    }
}
