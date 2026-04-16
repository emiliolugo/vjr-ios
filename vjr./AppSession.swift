//
//  AppSession.swift
//  vjr.
//
//  Clears persisted login state. Keys must match @AppStorage in LoginView / RootView.

import Foundation

enum AppSession {
    static func end() {
        let d = UserDefaults.standard
        d.removeObject(forKey: "currentUsername")
        d.removeObject(forKey: "currentUserId")
        d.removeObject(forKey: "currentUserPrismaId")
        d.removeObject(forKey: "currentUserIsPrivate")
    }
}
