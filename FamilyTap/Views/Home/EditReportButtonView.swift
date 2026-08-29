//
//  EditReportButtonView.swift
//  FamilyTap
//
//  BUTTON-002 (spec section 14). Reached by long-pressing a card on
//  HomeView — tapping is reserved for reporting once that lands.
//

import SwiftUI

struct EditReportButtonView: View {
    let button: ReportButton
    var onFinished: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ReportButtonFormViewModel()
    @State private var showDeleteConfirmation = false

    var body: some View {
        Form {
            Section("ボタン名") {
                TextField("例）犬に朝ごはんあげた", text: $viewModel.label)
            }

            Section("アイコン（絵文字）") {
                ReportButtonIconPicker(selection: $viewModel.icon)
            }

            Section("ボタン種別") {
                ReportButtonTypePicker(selection: $viewModel.type)
            }

            Section("並び順") {
                Stepper("表示順: \(viewModel.sortOrder)", value: $viewModel.sortOrder, in: 0...99)
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    Task {
                        if await viewModel.update(buttonId: button.id) {
                            dismiss()
                            onFinished()
                        }
                    }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("保存する")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(viewModel.isLoading)
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Text("削除する")
                        .frame(maxWidth: .infinity)
                }
                .disabled(viewModel.isLoading)
            }
        }
        .navigationTitle("ボタンを編集")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadForEditing(button) }
        .confirmationDialog(
            "このボタンを削除しますか？",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("削除する", role: .destructive) {
                Task {
                    if await viewModel.delete(buttonId: button.id) {
                        dismiss()
                        onFinished()
                    }
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
    }
}

#Preview {
    NavigationStack {
        EditReportButtonView(
            button: ReportButton(
                id: UUID(),
                familyId: UUID(),
                label: "犬の散歩に行った",
                icon: "🚶",
                type: .normal,
                sortOrder: 0,
                isActive: true,
                createdBy: nil,
                createdAt: .now,
                updatedAt: .now
            ),
            onFinished: {}
        )
    }
}
