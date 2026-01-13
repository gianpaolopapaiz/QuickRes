//
//  QuickResApp.swift
//  QuickRes
//
//  Created by Gianpaolo Papaiz on 08/01/26.
//

import SwiftUI

@main
struct QuickResApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Empty Settings scene - actual settings window is managed by AppDelegate
        Settings {
            EmptyView()
        }
    }
}
