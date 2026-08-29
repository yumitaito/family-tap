//
//  ReportButtonTypePicker.swift
//  FamilyTap
//
//  Two selectable rows for `normal` vs `daily` (spec section 10/13:
//  「通常 (押すたびに記録)」/「毎日リセット (当日1回の報告)」).
//

import SwiftUI

struct ReportButtonTypePicker: View {
    @Binding var selection: ReportButtonType

    var body: some View {
        row(type: .normal, title: "通常", subtitle: "押すたびに記録")
        row(type: .daily, title: "毎日リセット", subtitle: "当日1回の報告")
    }

    private func row(type: ReportButtonType, title: String, subtitle: String) -> some View {
        Button {
            selection = type
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if selection == type {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    Form {
        Section("ボタン種別") {
            ReportButtonTypePicker(selection: .constant(.normal))
        }
    }
}
