# ClipboardManager

A powerful macOS menu bar clipboard manager built in Objective-C. Keep track of your clipboard history, pin important items, and cycle through previous copies with a keyboard shortcut.

## Features

### 📋 Clipboard History
- Automatically tracks the last 20 items you copy
- View your clipboard history from the menu bar
- Click any item to copy it back to your clipboard

### 📌 Pin Important Items
- Hold **Option (⌥)** while clicking to pin/unpin items
- Pinned items are marked with 📌 and won't be removed when history fills up
- Clear button only removes unpinned items

### ⌨️ Keyboard Cycling
- Press **Cmd+Ctrl+V** to cycle backward through clipboard history
- Press multiple times to keep going back
- Clipboard updates immediately so you can paste right away
- Selected item automatically moves to the top after 0.5 seconds of inactivity
- **Toast notification** appears in the bottom-right corner showing what was copied

### 🎯 Smart Features
- Duplicate detection - copying the same thing twice doesn't create duplicates
- Most recent items appear first
- Clean, native macOS menu bar interface

## Installation

### Requirements
- macOS 10.13 or later
- Xcode (for building from source)
- Apple Developer account (can be free)

### Building from Source

1. **Clone or download this project**

2. **Open in Xcode**
   ```bash
   open ClipboardManager.xcodeproj
   ```

3. **Configure Code Signing**
   - Select the project in Xcode
   - Go to Signing & Capabilities
   - Enable "Automatically manage signing"
   - Select your Team (Apple ID)

4. **Build and Run**
   - Press Cmd+R or Product → Run
   - The app will appear in your menu bar as 📋

5. **Grant Accessibility Permission** (Required for hotkey)
   - On first launch, you'll be prompted for Accessibility permission
   - Click "Open System Settings"
   - Find ClipboardManager in the list and toggle it ON
   - Restart the app

   **Note:** If the app doesn't appear in Accessibility settings:
   - Build the app (Cmd+B)
   - Go to Product → Show Build Folder in Finder
   - Navigate to Products → Debug → ClipboardManager.app
   - Copy it to your Applications folder
   - Run from Applications folder
   - Now grant permission

## Usage

### Basic Usage
1. Copy text as you normally would (Cmd+C)
2. Click the 📋 icon in your menu bar to see history
3. Click any item to copy it back to your clipboard
4. Paste as usual (Cmd+V)

### Pinning Items
1. Hold **Option (⌥)** key
2. Click on an item in the menu - it will show "PIN" or "UNPIN"
3. Pinned items stay at the top and won't be removed

### Keyboard Cycling
1. Press **Cmd+Ctrl+V** to cycle to the previous clipboard item
2. A HUD-style toast notification appears showing the copied text
3. Press again to keep going back through history
4. Paste immediately with Cmd+V
5. After 0.5 seconds, the selected item moves to the front of your history

### Clearing History
- Click "Clear" to remove all unpinned items
- Pinned items are preserved

## Technical Details

### Architecture
- **Language:** Objective-C
- **Frameworks:** Cocoa, ApplicationServices
- **Clipboard Detection:** Timer-based polling (0.5s interval)
- **Event Monitoring:** Global keyboard event monitor for hotkey

### File Structure
```
ClipboardManager/
├── AppDelegate.h          # Main app delegate header
├── AppDelegate.m          # Main app delegate implementation
├── main.m                 # App entry point
└── Info.plist            # App configuration
```

### Key Components

**Clipboard Monitoring**
- Polls `NSPasteboard` every 0.5 seconds
- Compares `changeCount` to detect new copies
- Automatically adds new items to history

**History Management**
- `NSMutableArray` stores last 20 items
- Newest items at index 0
- Duplicate detection and removal
- Pin support prevents automatic removal

**Keyboard Hotkey**
- Uses `addGlobalMonitorForEventsMatchingMask`
- Requires Accessibility permission
- Detects Cmd+Ctrl+V anywhere on the system

**Cycle Mechanism**
- Increments index through history array
- Updates clipboard immediately for instant pasting
- Timer delays finalization (moving item to front)
- Cancels and restarts timer on each press

**Toast Notification**
- Custom `NSPanel` with HUD-style appearance
- Dark, rounded, semi-transparent bezel (matching macOS system HUDs)
- Positioned in bottom-right corner
- Fade in/out animations using `NSAnimationContext`
- Auto-dismisses after 1.5 seconds
- Non-activating panel (`NSNonactivatingPanelMask`) prevents focus stealing
- Window level set to `NSScreenSaverWindowLevel` for always-on-top display
- Thread-safe: UI updates dispatched to main queue

## Customization

### Change Hotkey
In `registerHotkey` method, modify the key detection:
```objc
BOOL isVKey = event.keyCode == 9;  // Change 9 to different keycode
```

Common keycodes: C=8, V=9, X=7, Z=6

### Change History Size
In `applicationDidFinishLaunching`:
```objc
self.maxHistorySize = 20;  // Change to desired number
```

### Change Cycle Timer Duration
In `cycleToPreviousClipboard`:
```objc
scheduledTimerWithTimeInterval:0.5  // Change 0.5 to desired seconds
```

### Customize Toast Appearance
In `showToast` method:

**Position:**
```objc
// Bottom-right (default)
CGFloat x = NSMaxX(screenFrame) - 320;
CGFloat y = NSMinY(screenFrame) + 20;

// Bottom-center (like volume HUD)
CGFloat x = NSMidX(screenFrame) - 150;
CGFloat y = NSMinY(screenFrame) + 100;

// Center screen (like globe button)
CGFloat x = NSMidX(screenFrame) - 150;
CGFloat y = NSMidY(screenFrame) - 40;
```

**Size:**
```objc
NSMakeRect(0, 0, 300, 80)  // width, height
```

**Colors:**
```objc
toast.backgroundColor = [NSColor colorWithWhite:0.1 alpha:0.85];  // Dark transparent
contentLabel.textColor = [NSColor whiteColor];  // Text color
```

**Display duration:**
```objc
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), ...)  // 1.5 seconds
```

## Troubleshooting

### Hotkey doesn't work
- **Check Accessibility permission:** System Settings → Privacy & Security → Accessibility
- Make sure ClipboardManager is in the list and enabled
- Try removing and re-adding the app to the list
- Restart the app after granting permission

### App doesn't appear in Accessibility settings
- Build as Release instead of Debug
- Copy the app to /Applications folder
- Run from Applications, not from Xcode
- Make sure code signing is enabled

### Clipboard history isn't updating
- Check console logs for errors
- Verify the app is running (📋 appears in menu bar)
- Try copying different types of content (text only is supported)

### Items appear multiple times
- This is normal if you copy the same thing at different times
- The duplicate detection only prevents consecutive duplicates

### Toast notification doesn't appear
- Toast shows when using Cmd+Ctrl+V hotkey only (not when clicking menu items)
- Check console for "showToast called with:" log message
- Verify main thread dispatch: should see "On main thread: 1"
- If toast appears but immediately disappears, `toastPanel` property may be missing from header file

## Limitations

- **Text only:** Currently only supports text clipboard items
- **No persistence:** History is lost when app quits
- **Local only:** Global monitor requires Accessibility permission
- **macOS only:** Uses macOS-specific APIs

## Future Enhancements

Possible improvements:
- [ ] Image clipboard support
- [ ] Persistent storage (save history between sessions)
- [ ] Search/filter functionality
- [ ] Customizable hotkey via preferences
- [ ] AI-powered summarization for long text
- [ ] Multiple clipboard "slots" or categories
- [ ] Snippet templates
- [ ] Sync across devices

## Contributing

This is a learning project built to understand Objective-C and macOS development. Feel free to fork and modify!

## License

MIT License - feel free to use this code for learning or building your own clipboard manager.

## Credits

Built as a learning project to understand:
- Objective-C syntax and patterns
- macOS AppKit and system APIs
- Event monitoring and Accessibility
- Timer-based background tasks
- Menu bar app architecture
- Custom UI with NSPanel and animations
- Thread safety and main queue dispatch
- Window levels and focus management

## New Objective-C Concepts Demonstrated

### Toast Notification Implementation
- **NSPanel**: Creating custom floating windows
- **NSWindowStyleMask**: Borderless, non-activating panels
- **Window Levels**: `NSScreenSaverWindowLevel` for always-on-top
- **CALayer**: Rounded corners with `cornerRadius` and `masksToBounds`
- **NSAnimationContext**: Fade in/out animations with completion handlers
- **dispatch_async**: Ensuring UI updates happen on main thread
- **dispatch_after**: Delayed execution with GCD
- **Strong references**: Using `self.toastPanel` to prevent premature deallocation
- **Focus management**: `NSNonactivatingPanelMask` and `setIsVisible:` vs `orderFront:`

---

**Built with ❤️ and lots of `NSLog` statements**
