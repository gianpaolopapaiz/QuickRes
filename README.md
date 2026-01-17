# QuickRes

A lightweight macOS menu bar app for quickly switching display resolutions.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Multi-Display Support** — Works with built-in and external displays simultaneously
- **Per-Display Resolution Selection** — Select resolutions independently for each connected display
- **Display Names** — Shows actual monitor names (e.g., "LG UltraFine", "Dell P2415Q") instead of generic labels
- **Menu Bar Access** — Lives in your menu bar for instant access without cluttering your dock
- **One-Click Switching** — Change resolutions with a single click from the dropdown menu
- **Smart Filtering** — Shows resolutions that match your display's native aspect ratio
  - Built-in displays: Shows only HiDPI (Retina) resolutions
  - External displays: Shows both HiDPI and standard resolutions
- **HiDPI Labeling** — Clearly marks HiDPI resolutions with "(HiDPI)" in the menu
- **Current Resolution Indicator** — Checkmark shows your currently active resolution for each display
- **Auto-Detection** — Automatically detects when displays are connected or disconnected
- **Launch at Login** — Option to start automatically when you log in
- **Dock Visibility** — Toggle whether the app appears in your dock

## Screenshot

The menu bar dropdown displays all available resolutions organized by display:

```
┌─────────────────────────────┐
│ Display Resolution          │
├─────────────────────────────┤
│ Built-in                    │
│   ✓ 1920 × 1200 (HiDPI)    │
│     1680 × 1050 (HiDPI)     │
│     1440 × 900 (HiDPI)      │
│     1280 × 800 (HiDPI)      │
├─────────────────────────────┤
│ LG UltraFine                │
│   ✓ 3840 × 2160 (HiDPI)    │
│     2560 × 1440 (HiDPI)     │
│     1920 × 1080             │
├─────────────────────────────┤
│ Dell P2415Q                 │
│     2560 × 1440             │
│     1920 × 1080             │
├─────────────────────────────┤
│   Settings...           ⌘, │
├─────────────────────────────┤
│   Quit                  ⌘Q │
└─────────────────────────────┘
```

## Requirements

- macOS 14.0 (Sonoma) or later
- Any Mac (with or without built-in Retina display)
- Supports both built-in and external displays

## Installation

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/gianpaolopapaiz/QuickRes.git
   ```

2. Open `QuickRes.xcodeproj` in Xcode

3. Build and run (⌘R)

## Usage

1. Click the display icon in your menu bar
2. Browse resolutions organized by display (Built-in, then external displays by name)
3. Select any resolution from the list
4. The selected display will immediately switch to the chosen resolution

### Multi-Display Setup

When multiple displays are connected:
- Each display appears as a section in the menu with its actual name
- Resolutions are listed under each display section
- The checkmark (✓) indicates the current resolution for each display
- Select resolutions independently for each display

### Settings

Access settings via the menu or press `⌘,`:

- **Launch at Login** — Automatically start QuickRes when you log in
- **Show in Dock** — Display the app icon in your dock (disabled by default)

## How It Works

QuickRes uses macOS Core Graphics and AppKit APIs to:

1. **Detect All Displays** — Enumerates all online displays (built-in and external) using `CGGetOnlineDisplayList`
2. **Get Display Names** — Retrieves actual monitor names from `NSScreen.localizedName` for each display
3. **Query Display Modes** — Queries all available display modes for each display using `CGDisplayCopyAllDisplayModes`
4. **Smart Filtering** — Filters resolutions based on display type:
   - Built-in displays: Only HiDPI (Retina) modes matching native aspect ratio
   - External displays: All modes (HiDPI and standard) matching native aspect ratio
5. **Apply Resolution** — Sets the selected resolution via `CGDisplaySetDisplayMode` for the specific display
6. **Auto-Detection** — Registers a `CGDisplayReconfigurationCallBack` to automatically refresh when displays are connected or disconnected

## Project Structure

```
QuickRes/
├── AppDelegate.swift       # Menu bar setup and menu handling
├── DisplayManager.swift    # Resolution detection and switching
├── SettingsManager.swift   # Preferences and launch at login
├── SettingsView.swift      # SwiftUI settings window
├── QuickResApp.swift       # App entry point
└── Assets.xcassets/        # App icons and colors
```

## License

MIT License — see [LICENSE](LICENSE) for details.

## Author

Created by [Gianpaolo Papaiz](https://github.com/gianpaolopapaiz)
