# QuickRes

A lightweight macOS menu bar app for quickly switching display resolutions.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Menu Bar Access** — Lives in your menu bar for instant access without cluttering your dock
- **One-Click Switching** — Change resolutions with a single click from the dropdown menu
- **Smart Filtering** — Shows only HiDPI (Retina) resolutions that match your display's native aspect ratio
- **Current Resolution Indicator** — Checkmark shows your currently active resolution
- **Launch at Login** — Option to start automatically when you log in
- **Dock Visibility** — Toggle whether the app appears in your dock

## Screenshot

The menu bar dropdown displays all available resolutions for your built-in display:

```
┌─────────────────────────┐
│ Display Resolution      │
├─────────────────────────┤
│ ✓ 1920 × 1200          │
│   1680 × 1050          │
│   1440 × 900           │
│   1280 × 800           │
├─────────────────────────┤
│   Settings...       ⌘, │
├─────────────────────────┤
│   Quit              ⌘Q │
└─────────────────────────┘
```

## Requirements

- macOS 14.0 (Sonoma) or later
- Mac with built-in Retina display

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
2. Select any resolution from the list
3. The display will immediately switch to the selected resolution

### Settings

Access settings via the menu or press `⌘,`:

- **Launch at Login** — Automatically start QuickRes when you log in
- **Show in Dock** — Display the app icon in your dock (disabled by default)

## How It Works

QuickRes uses macOS Core Graphics APIs to:

1. Detect your Mac's built-in display
2. Query all available display modes
3. Filter for HiDPI modes matching the native aspect ratio
4. Apply the selected resolution via `CGDisplaySetDisplayMode`

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
