//
//  FamilyGateView.swift
//  FamilyTap
//
//  FAMILY-001 (spec section 6/7): shown once signed in but not yet a
//  member of any family — the fork between 家族を作る and 家族に参加する.
//

import SwiftUI

struct FamilyGateView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "house.and.flag.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.accentColor)

                Text("家族グループに参加しましょう")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("家族を作成するか、招待コードで\n既存の家族に参加してください。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                NavigationLink {
                    CreateFamilyView()
                } label: {
                    Text("家族を作る")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                NavigationLink {
                    JoinFamilyView()
                } label: {
                    Text("家族に参加する")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    FamilyGateView()
        .environmentObject(FamilyStore())
}
