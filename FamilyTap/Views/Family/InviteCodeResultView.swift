//
//  InviteCodeResultView.swift
//  FamilyTap
//
//  Shown right after creating a family (spec section 17): displays the
//  generated invite code to share, then hands off to `onFinish` which the
//  caller uses to refresh FamilyStore and enter the main app.
//

import SwiftUI

struct InviteCodeResultView: View {
    let family: Family
    var onFinish: () -> Void

    @State private var didCopy = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text("\(family.name) を作成しました！")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("この招待コードを家族に共有して\n参加してもらいましょう。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                Text("招待コード")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(family.inviteCode)
                    .font(.system(.largeTitle, design: .monospaced).bold())
                    .tracking(2)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Button {
                UIPasteboard.general.string = family.inviteCode
                didCopy = true
            } label: {
                Text(didCopy ? "コピーしました ✓" : "コードをコピー")
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.bordered)

            Spacer()

            Button {
                onFinish()
            } label: {
                Text("完了")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    InviteCodeResultView(
        family: Family(id: UUID(), name: "弓田家", inviteCode: "ABCD1234", createdBy: UUID(), createdAt: .now),
        onFinish: {}
    )
}
