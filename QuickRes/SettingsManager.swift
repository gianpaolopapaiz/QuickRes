//
//  SettingsManager.swift
//  QuickRes
//
//  Created by Gianpaolo Papaiz on 08/01/26.
//

import Foundation
import ServiceManagement
import Combine

/// Manages app settings including launch at login
class SettingsManager: ObservableObject {
    
    static let shared = SettingsManager()
    
    @Published var launchAtLogin: Bool {
        didSet {
            setLaunchAtLogin(launchAtLogin)
        }
    }
    
    @Published var errorMessage: String?
    
    private init() {
        // Initialize with current state
        launchAtLogin = SMAppService.mainApp.status == .enabled
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
