//
//  NotificationSettingsView.swift
//  FamilyTap
//
//  Spec section 44's 通知設定 row. Shows the *real* system authorization
//  state rather than fake on/off toggles FamilyTap can't actually
//  control — iOS doesn't let an app silently flip its own notification
//  permission, only request it once and otherwise point the user at
//  Settings.
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @State private var status: UNAuthorizationStatus = .notDetermined

    var body: some View {
        List {
            Section {
                LabeledContent("プッシュ通知", value: statusText)
            } footer: {
                Text(statusFooter)
            }

            if status == .denied {
                Section {
                    Button("設定アプリを開く") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
        }
        .navigationTitle("通知設定")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            status = await NotificationService.authorizationStatus()
        }
    }

    private var statusText: String {
        switch status {
        case .authorized, .provisional, .ephemeral:
            "オン"
        case .denied:
            "オフ"
        case .notDetermined:
            "未設定"
        @unknown default:
            "不明"
        }
    }

    private var statusFooter: String {
        switch status {
        case .denied:
            "通知がオフになっています。家族の報告を受け取るには、設定アプリからFamily Tapの通知を有効にしてください。"
        case .notDetermined:
            "ホーム画面を開くと通知の許可を確認します。"
        default:
            "家族が報告すると通知でお知らせします。"
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
