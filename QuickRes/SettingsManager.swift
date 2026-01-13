//
//  SettingsManager.swift
//  QuickRes
//
//  Created by Gianpaolo Papaiz on 08/01/26.
//

import Foundation
import ServiceManagement
import AppKit
import Combine

/// Manages app settings including launch at login
class SettingsManager: ObservableObject {
    
    static let shared = SettingsManager()
    
    private let showInDockKey = "showInDock"
    
    @Published var launchAtLogin: Bool {
        didSet {
            setLaunchAtLogin(launchAtLogin)
        }
    }
    
    @Published var showInDock: Bool {
        didSet {
            UserDefaults.standard.set(showInDock, forKey: showInDockKey)
            applyDockVisibility()
        }
    }
    
    @Published var errorMessage: String?
    
    private init() {
        // Initialize with current state
        launchAtLogin = SMAppService.mainApp.status == .enabled
        
        // Default to not showing in dock (menu bar app)
        showInDock = UserDefaults.standard.object(forKey: showInDockKey) as? Bool ?? false
    }
    
    /// Applies the dock visibility setting
    func applyDockVisibility() {
        if showInDock {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    /// Refreshes the launch at login state from the system
    func refresh() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
    
    /// Sets the launch at login state
    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            errorMessage = nil
        } catch {
            errorMessage = "Failed to update login item: \(error.localizedDescription)"
            // Revert the published value to match actual state
            DispatchQueue.main.async {
                self.launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }
    }
}
