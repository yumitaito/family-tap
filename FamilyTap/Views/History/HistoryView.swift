//
//  HistoryView.swift
//  FamilyTap
//
//  HISTORY-001 (spec section 15, 47): every family member's reports,
//  newest first, grouped by day. Long-press on an entry to 取り消し
//  (cancel) it — only offered on the current user's own entries, since
//  reporting is individually managed (unlike a DAILY card on Home, which
//  any family member can edit).
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var familyStore: FamilyStore
    @StateObject private var viewModel = HistoryViewModel()
    @State private var pendingCancelEntry: HistoryEntry?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if viewModel.entries.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(viewModel.groupedEntries, id: \.label) { group in
                            Section(group.label) {
                                ForEach(group.entries) { entry in
                                    HistoryRow(entry: entry)
                                        .contentShape(Rectangle())
                                        .onLongPressGesture {
                                            guard entry.reporterId == viewModel.currentUserId else { return }
                                            pendingCancelEntry = entry
                                        }
                                }
                            }
                        }
                    }
                    .refreshable { await load() }
                }
            }
            .navigationTitle("履歴")
            .task { await load() }
            .confirmationDialog(
                "この報告を取り消しますか？",
                isPresented: Binding(
                    get: { pendingCancelEntry != nil },
                    set: { isPresented in if !isPresented { pendingCancelEntry = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("取り消す", role: .destructive) {
                    if let entry = pendingCancelEntry {
                        Task { await viewModel.cancel(entry: entry) }
                    }
                    pendingCancelEntry = nil
                }
                Button("キャンセル", role: .cancel) {
                    pendingCancelEntry = nil
                }
            }
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("まだ報告はありません")
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func load() async {
        guard let familyId = familyStore.family?.id else { return }
        await viewModel.load(familyId: familyId)
    }
}

#Preview {
    HistoryView()
        .environmentObject(FamilyStore())
}
