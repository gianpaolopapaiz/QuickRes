//
//  DisplayManager.swift
//  QuickRes
//
//  Created by Gianpaolo Papaiz on 08/01/26.
//

import Foundation
import CoreGraphics
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
        
        var description: String {
            "\(width) × \(height)"
        }
        
        init(mode: CGDisplayMode) {
            self.mode = mode
            self.width = mode.width
            self.height = mode.height
            self.id = "\(width)x\(height)"
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: Resolution, rhs: Resolution) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    @Published var currentResolution: Resolution?
    @Published var availableResolutions: [Resolution] = []
    @Published var errorMessage: String?
    
    init() {
        refresh()
    }
    
    /// Gets the built-in display ID
    private func getBuiltInDisplayID() -> CGDirectDisplayID? {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
        var displayCount: UInt32 = 0
        
        let result = CGGetOnlineDisplayList(16, &displayIDs, &displayCount)
        guard result == .success else { return nil }
        
        for i in 0..<Int(displayCount) {
            if CGDisplayIsBuiltin(displayIDs[i]) != 0 {
                return displayIDs[i]
            }
        }
        
        // Fallback to main display if no built-in found
        return CGMainDisplayID()
    }
    
    /// Gets the native aspect ratio of the display
    private func getNativeAspectRatio(displayID: CGDirectDisplayID) -> Double? {
        let nativeWidth = CGDisplayPixelsWide(displayID)
        let nativeHeight = CGDisplayPixelsHigh(displayID)
        guard nativeHeight > 0 else { return nil }
        return Double(nativeWidth) / Double(nativeHeight)
    }
    
    /// Refreshes both current resolution and available resolutions
    func refresh() {
        refreshCurrentResolution()
        refreshAvailableResolutions()
    }
    
    /// Refreshes the current resolution from the display
    private func refreshCurrentResolution() {
        guard let displayID = getBuiltInDisplayID(),
              let mode = CGDisplayCopyDisplayMode(displayID) else {
            currentResolution = nil
            return
        }
        
        currentResolution = Resolution(mode: mode)
    }
    
    /// Gets the default scaled resolutions that fill the entire screen
    private func refreshAvailableResolutions() {
        guard let displayID = getBuiltInDisplayID() else {
            availableResolutions = []
            return
        }
        
        // Get native aspect ratio to filter full-screen resolutions
        guard let nativeAspectRatio = getNativeAspectRatio(displayID: displayID) else {
            availableResolutions = []
            return
        }
        
        // Get all available display modes
        let options: CFDictionary = [
            kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue as Any
        ] as CFDictionary
        
        guard let modes = CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode] else {
            availableResolutions = []
            return
        }
        
        var resolutionMap: [String: Resolution] = [:]
        
        for mode in modes {
            // Only HiDPI (Retina) modes
            let isHiDPI = mode.pixelWidth > mode.width
            guard isHiDPI else { continue }
            
            // Only resolutions matching native aspect ratio (full screen)
            let modeAspectRatio = Double(mode.width) / Double(mode.height)
            let aspectRatioMatches = abs(modeAspectRatio - nativeAspectRatio) < 0.01
            guard aspectRatioMatches else { continue }
            
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
        
        availableResolutions = resolutions
    }
    
    /// Toggles between Default (1440×900) and More Space (1920×1200) resolutions
    func toggleResolution() {
        guard let current = currentResolution else {
            // If no current resolution, try to set default
            if let defaultRes = findResolution(width: Self.defaultResolution.width, height: Self.defaultResolution.height) {
                setResolution(defaultRes)
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
        
        if let targetRes = findResolution(width: targetWidth, height: targetHeight) {
            setResolution(targetRes)
        } else {
            errorMessage = "Target resolution \(targetWidth) × \(targetHeight) not available"
        }
    }
    
    /// Finds a resolution by width and height from available resolutions
    private func findResolution(width: Int, height: Int) -> Resolution? {
        return availableResolutions.first { $0.width == width && $0.height == height }
    }
    
    /// Sets the display to the specified resolution
    func setResolution(_ resolution: Resolution) {
        guard let displayID = getBuiltInDisplayID() else {
            errorMessage = "Could not find built-in display"
            return
        }
        
        let result = CGDisplaySetDisplayMode(displayID, resolution.mode, nil)
        
        if result == .success {
            errorMessage = nil
            refreshCurrentResolution()
        } else {
            errorMessage = "Failed to set resolution (error: \(result.rawValue))"
        }
    }
}
