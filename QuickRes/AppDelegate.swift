//
//  AppDelegate.swift
//  QuickRes
//
//  Created by Gianpaolo Papaiz on 08/01/26.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    private var statusItem: NSStatusItem!
    private var displayManager = DisplayManager()
    private var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "display", accessibilityDescription: "QuickRes")
        }
        
        // Create and assign menu
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }
    
    // NSMenuDelegate - rebuild menu each time it opens to show current state
    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()
        
        // Header
        let headerItem = NSMenuItem(title: "Display Resolution", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        menu.addItem(NSMenuItem.separator())
        
        // Resolution options
        displayManager.refresh()
        for resolution in displayManager.availableResolutions {
            let item = NSMenuItem(
                title: resolution.description,
                action: #selector(resolutionSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = resolution
            
            // Mark current resolution with checkmark
            if resolution.id == displayManager.currentResolution?.id {
                item.state = .on
            }
            
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    @objc private func resolutionSelected(_ sender: NSMenuItem) {
        guard let resolution = sender.representedObject as? DisplayManager.Resolution else { return }
        displayManager.setResolution(resolution)
    }
    
    @objc private func openSettings() {
        // Activate the app
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        
        // Find or create settings window
        if let existingWindow = NSApp.windows.first(where: { $0.identifier?.rawValue == "settings" }) {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        // Create settings window with SwiftUI view
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.identifier = NSUserInterfaceItemIdentifier("settings")
        window.title = "Settings"
        window.styleMask = [.titled, .closable]
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        settingsWindow = window
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
