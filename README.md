# ClipboardManager

A native macOS menu bar clipboard manager built in Objective-C. Tracks clipboard history, pins important items, and cycles through previous copies with a keyboard shortcut.

> **Built to learn:** This project demonstrates Objective-C fundamentals, macOS AppKit APIs, event monitoring, custom UI, animations, and thread safety. See [Technical Highlights](#technical-highlights) below.

![Menu Bar App](https://img.shields.io/badge/macOS-Menu%20Bar%20App-blue)
![Language](https://img.shields.io/badge/Language-Objective--C-orange)

---

## Features

- **📋 Clipboard History** - Automatically tracks last 20 copied items
- **📌 Pin Items** - Hold Option while clicking to pin/unpin (pinned items won't be cleared)
- **⌨️ Keyboard Cycling** - Press Cmd+Ctrl+V to cycle back through history
- **🎯 HUD Toast** - macOS-style notification shows what you copied
- **🧹 Smart Management** - Duplicate detection, auto-cleanup of old items

---

## Quick Start

### Requirements
- macOS 10.13+
- Xcode with valid Apple Developer account (free account works)

### Installation

1. **Clone and open in Xcode**
   ```bash
   git clone <your-repo>
   cd ClipboardManager
   open ClipboardManager.xcodeproj
   ```

2. **Configure signing** (required for Accessibility permissions)
   - Select project → Target → Signing & Capabilities
   - Enable "Automatically manage signing"
   - Select your Team

3. **Build and run**
   ```bash
   # Press Cmd+R in Xcode, or:
   Product → Run
   ```

4. **Grant Accessibility permission**
   - Click "Open System Settings" when prompted
   - Toggle ClipboardManager ON in Privacy & Security → Accessibility
   - Restart the app
   
   **If app doesn't appear in Accessibility list:**
   - Copy built app from `Products/Debug/ClipboardManager.app` to `/Applications`
   - Run from Applications folder
   - Now grant permission

---

## Usage

**Basic:**
- Copy text normally (Cmd+C) → appears in history
- Click 📋 menu bar icon → click any item to re-copy it

**Pinning:**
- Hold **Option (⌥)** → menu shows PIN/UNPIN
- Click to pin → item won't be removed when history fills

**Keyboard cycling:**
- Press **Cmd+Ctrl+V** → cycles to previous clipboard
- Press again → keeps going back
- Paste immediately with Cmd+V
- HUD toast shows what you copied

---

## Technical Highlights

**What I learned building this:**

| Concept | Implementation |
|---------|---------------|
| **Event Monitoring** | Global keyboard listener with `addGlobalMonitorForEventsMatchingMask` |
| **Accessibility** | AX APIs for system-wide hotkey detection |
| **Custom UI** | `NSPanel` with HUD styling, rounded corners, animations |
| **Thread Safety** | Main queue dispatch for UI updates, timer invalidation |
| **Memory Management** | Strong references to prevent premature deallocation (ARC) |
| **Animations** | `NSAnimationContext` for fade in/out with completion handlers |
| **Window Management** | Non-activating panels, window levels, focus control |
| **Timers** | `NSTimer` for polling clipboard and auto-finalization |

**Key files:**
- `AppDelegate.m` - Core logic (~350 lines)
- Menu bar integration with `NSStatusBar`
- Clipboard polling with `NSPasteboard`
- Custom toast with `NSPanel` + `CALayer`

---

## Customization

**Change hotkey** (in `registerHotkey`):
```objc
BOOL isVKey = event.keyCode == 9;  // 9 = V key, 8 = C, 7 = X
```

**Toast position** (in `showToast`):
```objc
// Bottom-right (default)
CGFloat x = NSMaxX(screenFrame) - 320;
CGFloat y = NSMinY(screenFrame) + 20;

// Center (like volume HUD)
CGFloat x = NSMidX(screenFrame) - 150;
CGFloat y = NSMinY(screenFrame) + 100;
```

**History size** (in `applicationDidFinishLaunching`):
```objc
self.maxHistorySize = 20;  // Change to any number
```

---

## Troubleshooting

**Hotkey doesn't work**
→ Grant Accessibility permission (System Settings → Privacy & Security → Accessibility)

**App not in Accessibility list**
→ Copy to /Applications, run from there, then grant permission

**Toast doesn't appear**
→ Only shows when using Cmd+Ctrl+V hotkey (not menu clicks)

**History not updating**
→ App only supports text (no images/files yet)

---

## License

MIT - Free to use for learning or personal projects

---

**Built with Objective-C • No external dependencies • ~400 lines of code**
