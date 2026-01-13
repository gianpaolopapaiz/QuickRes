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
    
    /// Flag to prevent didSet from triggering during programmatic updates
    private var isRefreshing = false
    
    @Published var launchAtLogin: Bool {
        didSet {
            guard !isRefreshing else { return }
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
        // Initialize with current state (no didSet triggered during init)
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
        isRefreshing = true
        launchAtLogin = SMAppService.mainApp.status == .enabled
        isRefreshing = false
        // Clear any stale error when refreshing
        errorMessage = nil
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
            isRefreshing = true
            launchAtLogin = SMAppService.mainApp.status == .enabled
            isRefreshing = false
        }
    }
}
