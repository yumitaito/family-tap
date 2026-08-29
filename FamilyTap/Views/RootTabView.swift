//
//  RootTabView.swift
//  FamilyTap
//
//  Top-level tab navigation (spec section 43), shown once signed in and
//  belonging to a family (spec section 6).
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }

            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "clock")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
        }
        .task {
            // Spec section 35: ask once the user is fully in the app.
            // Safe to call every time this view appears — iOS only shows
            // the system prompt the first time either way.
            await NotificationService.requestAuthorizationAndRegister()
        }
    }
}

#Preview {
    RootTabView()
}
