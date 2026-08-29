//
//  HomeView.swift
//  FamilyTap
//
//  HOME-001 (spec section 8, 40, 47). DAILY-type buttons show as status
//  rows in「今日の状態」with today's (Asia/Tokyo) report state (spec
//  section 10/31); NORMAL-type buttons show as a tappable grid under
//  「報告する」. Both report on tap (DAILY buttons confirm first if
//  already reported today, spec section 33) and both open edit
//  (BUTTON-002) on long-press.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var familyStore: FamilyStore
    @StateObject private var viewModel = HomeViewModel()
    @State private var editingButton: ReportButton?
    @State private var pendingDailyReport: ReportButton?

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private var dailyButtons: [ReportButton] {
        viewModel.buttons.filter { $0.type == .daily }
    }

    private var normalButtons: [ReportButton] {
        viewModel.buttons.filter { $0.type == .normal }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                content
                    .padding()
            }
            .navigationTitle(familyStore.family?.name ?? "Family Tap")
            .task { await load() }
            .refreshable { await load() }
            .navigationDestination(item: $editingButton) { button in
                EditReportButtonView(button: button) {
                    Task { await load() }
                }
            }
            .confirmationDialog(
                "今日はすでに報告済みです。もう一度報告しますか？",
                isPresented: Binding(
                    get: { pendingDailyReport != nil },
                    set: { isPresented in if !isPresented { pendingDailyReport = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("報告する") {
                    if let button = pendingDailyReport {
                        report(button: button)
                    }
                    pendingDailyReport = nil
                }
                Button("キャンセル", role: .cancel) {
                    pendingDailyReport = nil
                }
            }
            .overlay(alignment: .bottom) {
                if let toast = viewModel.toast {
                    ToastView(state: toast)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .task(id: toast) {
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            withAnimation { viewModel.toast = nil }
                        }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.toast)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.subheadline)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
        } else if viewModel.buttons.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 28) {
                if !dailyButtons.isEmpty {
                    dailyStatusSection
                }
                reportButtonsGrid
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)
            Text("まだ報告ボタンがありません")
                .font(.headline)
            Text("家族で使う報告ボタンを\n作ってみましょう。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let familyId = familyStore.family?.id {
                NavigationLink {
                    CreateReportButtonView(familyId: familyId) {
                        Task { await load() }
                    }
                } label: {
                    Label("最初のボタンを作る", systemImage: "plus")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var dailyStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日の状態")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(dailyButtons) { button in
                    DailyStatusCard(
                        button: button,
                        status: viewModel.dailyStatuses[button.id],
                        isReporting: viewModel.reportingButtonIDs.contains(button.id),
                        onTap: { handleDailyTap(button: button) },
                        onLongPress: { editingButton = button }
                    )
                }
            }
        }
    }

    private var reportButtonsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("報告する")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(normalButtons) { button in
                    ReportButtonCard(
                        button: button,
                        isReporting: viewModel.reportingButtonIDs.contains(button.id),
                        onTap: { report(button: button) },
                        onLongPress: { editingButton = button }
                    )
                }

                if let familyId = familyStore.family?.id {
                    NavigationLink {
                        CreateReportButtonView(familyId: familyId) {
                            Task { await load() }
                        }
                    } label: {
                        AddReportButtonTile()
                    }
                }
            }
        }
    }

    private func load() async {
        guard let familyId = familyStore.family?.id else { return }
        await viewModel.load(familyId: familyId)
    }

    private func report(button: ReportButton) {
        guard let familyId = familyStore.family?.id else { return }
        Task { await viewModel.report(button: button, familyId: familyId) }
    }

    /// DAILY buttons that already have a report today ask for confirmation
    /// first (spec section 33); everything else reports immediately.
    private func handleDailyTap(button: ReportButton) {
        if viewModel.dailyStatuses[button.id] != nil {
            pendingDailyReport = button
        } else {
            report(button: button)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(FamilyStore())
}
