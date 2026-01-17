//
//  DisplayManager.swift
//  QuickRes
//
//  Created by Gianpaolo Papaiz on 08/01/26.
//

import Foundation
import CoreGraphics
import AppKit
import Combine

/// Manages display resolution detection and switching
class DisplayManager: ObservableObject {
    
    // Target resolutions for quick toggle
    static let defaultResolution = (width: 1440, height: 900)
    static let moreSpaceResolution = (width: 1920, height: 1200)
    
    struct Resolution: Identifiable, Hashable {
        let id: String
        let width: Int
        let height: Int
        let mode: CGDisplayMode
        let isHiDPI: Bool
        
        var description: String {
            if isHiDPI {
                return "\(width) × \(height) (HiDPI)"
            } else {
                return "\(width) × \(height)"
            }
        }
        
        init(mode: CGDisplayMode) {
            self.mode = mode
            self.width = mode.width
            self.height = mode.height
            self.isHiDPI = mode.pixelWidth > mode.width
            self.id = "\(width)x\(height)"
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: Resolution, rhs: Resolution) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    struct Display: Identifiable {
        let id: CGDirectDisplayID
        let name: String
        let isBuiltIn: Bool
        var currentResolution: Resolution?
        var availableResolutions: [Resolution]
    }
    
    struct ResolutionMenuItem {
        let resolution: Resolution
        let displayID: CGDirectDisplayID
    }
    
    @Published var displays: [Display] = []
    @Published var errorMessage: String?
    
    private var callbackUserInfo: UnsafeMutableRawPointer?
    
    init() {
        setupDisplayReconfigurationCallback()
        refresh()
    }
    
    deinit {
        if let userInfo = callbackUserInfo {
            CGDisplayRemoveReconfigurationCallback(displayReconfigurationCallback, userInfo)
        }
    }
    
    /// Gets all online displays
    private func getAllDisplays() -> [CGDirectDisplayID] {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 32)
        var displayCount: UInt32 = 0
        
        let result = CGGetOnlineDisplayList(32, &displayIDs, &displayCount)
        guard result == .success else { return [] }
        
        return Array(displayIDs.prefix(Int(displayCount)))
    }
    
    /// Gets the native aspect ratio of the display (based on physical dimensions, not current resolution)
    private func getNativeAspectRatio(displayID: CGDirectDisplayID) -> Double? {
        let nativeWidth = CGDisplayPixelsWide(displayID)
        let nativeHeight = CGDisplayPixelsHigh(displayID)
        guard nativeHeight > 0 else { return nil }
        return Double(nativeWidth) / Double(nativeHeight)
    }
    
    /// Gets the display name from the system
    private func getDisplayName(displayID: CGDirectDisplayID, isBuiltIn: Bool, externalIndex: Int) -> String {
        // Try to get the display name from NSScreen
        for screen in NSScreen.screens {
            if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
                let screenDisplayID = CGDirectDisplayID(screenNumber.uint32Value)
                if screenDisplayID == displayID {
                    return screen.localizedName
                }
            }
        }
        
        // Fallback to generic names if we can't find the screen
        if isBuiltIn {
            return "Built-in"
        } else {
            return "External Display \(externalIndex)"
        }
    }
    
    /// Refreshes all displays and their resolutions
    func refresh() {
        let displayIDs = getAllDisplays()
        var builtInCount = 0
        var externalCount = 0
        var newDisplays: [Display] = []
        
        // Sort displays: built-in first, then external by displayID
        let sortedDisplayIDs = displayIDs.sorted { id1, id2 in
            let isBuiltIn1 = CGDisplayIsBuiltin(id1) != 0
            let isBuiltIn2 = CGDisplayIsBuiltin(id2) != 0
            
            if isBuiltIn1 && !isBuiltIn2 {
                return true
            } else if !isBuiltIn1 && isBuiltIn2 {
                return false
            } else {
                return id1 < id2
            }
        }
        
        for displayID in sortedDisplayIDs {
            let isBuiltIn = CGDisplayIsBuiltin(displayID) != 0
            let externalIndex: Int
            let name: String
            
            if isBuiltIn {
                builtInCount += 1
                externalIndex = 0
                name = getDisplayName(displayID: displayID, isBuiltIn: true, externalIndex: 0)
            } else {
                externalCount += 1
                externalIndex = externalCount
                name = getDisplayName(displayID: displayID, isBuiltIn: false, externalIndex: externalCount)
            }
            
            let display = refreshDisplay(displayID: displayID, name: name, isBuiltIn: isBuiltIn)
            newDisplays.append(display)
        }
        
        displays = newDisplays
    }
    
    /// Refreshes a single display's current resolution and available resolutions
    private func refreshDisplay(displayID: CGDirectDisplayID, name: String, isBuiltIn: Bool) -> Display {
        // Get current resolution
        var currentResolution: Resolution? = nil
        if let mode = CGDisplayCopyDisplayMode(displayID) {
            currentResolution = Resolution(mode: mode)
        }
        
        // Get available resolutions
        let availableResolutions = getAvailableResolutions(for: displayID, isBuiltIn: isBuiltIn)
        
        return Display(
            id: displayID,
            name: name,
            isBuiltIn: isBuiltIn,
            currentResolution: currentResolution,
            availableResolutions: availableResolutions
        )
    }
    
    /// Gets the default scaled resolutions that fill the entire screen for a specific display
    private func getAvailableResolutions(for displayID: CGDirectDisplayID, isBuiltIn: Bool) -> [Resolution] {
        // Get native aspect ratio to filter full-screen resolutions
        guard let nativeAspectRatio = getNativeAspectRatio(displayID: displayID) else {
            return []
        }
        
        // Get all available display modes (don't show duplicate low-res modes)
        let options: CFDictionary = [
            kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanFalse as Any
        ] as CFDictionary
        
        guard let modes = CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode] else {
            return []
        }
        
        var resolutionMap: [String: Resolution] = [:]
        
        for mode in modes {
            // Skip modes that are unreasonably small
            if mode.width < 640 || mode.height < 480 {
                continue
            }
            
            // For built-in displays, only show HiDPI (Retina) modes
            // For external displays, show both HiDPI and non-HiDPI modes
            if isBuiltIn {
                let isHiDPI = mode.pixelWidth > mode.width
                guard isHiDPI else { continue }
            }
            
            // Only resolutions matching native aspect ratio (full screen)
            let modeAspectRatio = Double(mode.width) / Double(mode.height)
            let aspectRatioMatches = abs(modeAspectRatio - nativeAspectRatio) < 0.01
            guard aspectRatioMatches else { continue }
            
            // Basic sanity check: pixel dimensions should be >= logical dimensions
            // (for HiDPI, pixelWidth > width; for non-HiDPI, pixelWidth == width)
            if mode.pixelWidth < mode.width || mode.pixelHeight < mode.height {
                continue
            }
            
            let resolution = Resolution(mode: mode)
            
            // Keep only one mode per resolution (prefer higher pixel density)
            if let existing = resolutionMap[resolution.id] {
                if mode.pixelWidth > existing.mode.pixelWidth {
                    resolutionMap[resolution.id] = resolution
                }
            } else {
                resolutionMap[resolution.id] = resolution
            }
        }
        
        // Sort by width descending (More Space → Larger Text)
        var resolutions = Array(resolutionMap.values)
        resolutions.sort { $0.width > $1.width }
        
        return resolutions
    }
    
    /// Toggles between Default (1440×900) and More Space (1920×1200) resolutions for the first display
    func toggleResolution() {
        guard let firstDisplay = displays.first else { return }
        
        guard let current = firstDisplay.currentResolution else {
            // If no current resolution, try to set default
            if let defaultRes = findResolution(width: Self.defaultResolution.width, height: Self.defaultResolution.height, in: firstDisplay.availableResolutions) {
                setResolution(defaultRes, for: firstDisplay.id)
            }
            return
        }
        
        // Determine target: if currently at more space, go to default; otherwise go to more space
        let targetWidth: Int
        let targetHeight: Int
        
        if current.width == Self.moreSpaceResolution.width && current.height == Self.moreSpaceResolution.height {
            targetWidth = Self.defaultResolution.width
            targetHeight = Self.defaultResolution.height
        } else {
            targetWidth = Self.moreSpaceResolution.width
            targetHeight = Self.moreSpaceResolution.height
        }
        
        if let targetRes = findResolution(width: targetWidth, height: targetHeight, in: firstDisplay.availableResolutions) {
            setResolution(targetRes, for: firstDisplay.id)
        } else {
            errorMessage = "Target resolution \(targetWidth) × \(targetHeight) not available"
        }
    }
    
    /// Finds a resolution by width and height from available resolutions
    private func findResolution(width: Int, height: Int, in resolutions: [Resolution]) -> Resolution? {
        return resolutions.first { $0.width == width && $0.height == height }
    }
    
    /// Sets the display to the specified resolution
    func setResolution(_ resolution: Resolution, for displayID: CGDirectDisplayID) {
        let result = CGDisplaySetDisplayMode(displayID, resolution.mode, nil)
        
        if result == .success {
            errorMessage = nil
            // Refresh the specific display
            if let displayIndex = displays.firstIndex(where: { $0.id == displayID }) {
                let display = displays[displayIndex]
                let updatedDisplay = refreshDisplay(displayID: displayID, name: display.name, isBuiltIn: display.isBuiltIn)
                displays[displayIndex] = updatedDisplay
            }
        } else {
            errorMessage = "Failed to set resolution (error: \(result.rawValue))"
        }
    }
    
    /// Sets up the display reconfiguration callback to detect display connect/disconnect
    private func setupDisplayReconfigurationCallback() {
        callbackUserInfo = Unmanaged.passUnretained(self).toOpaque()
        CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallback, callbackUserInfo)
    }
}

/// Static callback function for display reconfiguration events
private func displayReconfigurationCallback(_ displayID: CGDirectDisplayID, _ flags: CGDisplayChangeSummaryFlags, _ userInfo: UnsafeMutableRawPointer?) {
    // Only refresh on display add/remove events (not mode changes, which we handle ourselves)
    if flags.contains(.addFlag) || flags.contains(.removeFlag) {
        DispatchQueue.main.async {
            if let userInfo = userInfo {
                let manager = Unmanaged<DisplayManager>.fromOpaque(userInfo).takeUnretainedValue()
                manager.refresh()
            }
        }
    }
}
