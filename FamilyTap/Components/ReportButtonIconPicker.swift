//
//  ReportButtonIconPicker.swift
//  FamilyTap
//
//  Emoji grid used by CreateReportButtonView / EditReportButtonView (spec
//  section 9/13).
//

import SwiftUI

struct ReportButtonIconPicker: View {
    @Binding var selection: String

    private let columns = Array(repeating: GridItem(.flexible()), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(ReportButtonIcons.choices, id: \.self) { emoji in
                Button {
                    selection = emoji
                } label: {
                    Text(emoji)
                        .font(.title2)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                        .background(
                            selection == emoji
                                ? Color.accentColor.opacity(0.2)
                                : Color(.tertiarySystemBackground)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selection == emoji ? Color.accentColor : .clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ReportButtonIconPicker(selection: .constant("🐶"))
        .padding()
}
