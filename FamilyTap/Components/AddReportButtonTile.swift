//
//  AddReportButtonTile.swift
//  FamilyTap
//
//  The dashed "＋ ボタンを追加" tile at the end of the HOME-001 grid (spec
//  section 40).
//

import SwiftUI

struct AddReportButtonTile: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.title2)
            Text("ボタンを追加")
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, minHeight: 96)
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .foregroundStyle(.tertiary)
        )
    }
}

#Preview {
    AddReportButtonTile()
        .padding()
}
