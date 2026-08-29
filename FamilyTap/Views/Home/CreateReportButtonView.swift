//
//  CreateReportButtonView.swift
//  FamilyTap
//
//  BUTTON-001 (spec section 13).
//

import SwiftUI

struct CreateReportButtonView: View {
    let familyId: UUID
    var onFinished: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ReportButtonFormViewModel()

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
                        if await viewModel.create(familyId: familyId) {
                            dismiss()
                            onFinished()
                        }
                    }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("作成する")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(viewModel.isLoading)
            }
        }
        .navigationTitle("新しいボタンを追加")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CreateReportButtonView(familyId: UUID(), onFinished: {})
    }
}
