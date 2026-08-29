//
//  NotificationService.swift
//  FamilyTap
//
//  Push permission request (spec section 35): "Family Tapから家族の報告を
//  受け取りますか？". Actually registering the resulting APNs token with
//  Supabase happens in `AppDelegate.didRegisterForRemoteNotifications...`,
//  once iOS calls back with the token.
//

import Foundation
import UIKit
import UserNotifications

enum NotificationService {
    /// Safe to call every time the app enters the main tabs (spec section
    /// 6) — iOS only shows the system prompt once and silently no-ops on
    /// later calls if the user already answered.
    @MainActor
    static func requestAuthorizationAndRegister() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else { return }
            UIApplication.shared.registerForRemoteNotifications()
        } catch {
            // Non-fatal: the user just won't get push notifications.
        }
    }

    /// Current authorization state, for SETTINGS-001's 通知設定 row (spec
    /// section 44) to reflect reality instead of a fake toggle.
    @MainActor
    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }
}
