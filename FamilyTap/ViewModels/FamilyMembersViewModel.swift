//
//  FamilyMembersViewModel.swift
//  FamilyTap
//
//  Backs FamilyMembersView (FAMILY-004).
//

import Foundation

@MainActor
final class FamilyMembersViewModel: ObservableObject {
    @Published private(set) var members: [FamilyMemberWithProfile] = []
    @Published private(set) var isLoading = true
    @Published var errorMessage: String?

    func load(familyId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            members = try await FamilyService.shared.fetchMembers(familyId: familyId)
            errorMessage = nil
        } catch {
            errorMessage = "メンバー一覧を取得できませんでした。"
        }
    }
}
