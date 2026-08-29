//
//  FamilyTapApp.swift
//  FamilyTap
//
//  App entry point.
//

import SwiftUI

@main
struct FamilyTapApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
