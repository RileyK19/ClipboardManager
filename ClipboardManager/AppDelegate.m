//
//  AppDelegate.m
//  ClipboardManager
//
//  Created by Riley Koo on 4/22/26.
//

#import "AppDelegate.h"
#import <ApplicationServices/ApplicationServices.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.clipboardHistory = [NSMutableArray array];
    self.maxHistorySize = 20;
    self.lastChangeCount = 0;
    self.pinned = [NSMutableArray array];
    self.currentHistoryIndex = 0;
    
    [self setupMenuBar];
    [self startClipboardMonitoring];
    
    // Check accessibility permission BEFORE registering hotkey
    [self checkAccessibilityPermission];
    [self registerHotkey];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.clipboardTimer invalidate];
    
    if (self.cycleResetTimer) {
        [self.cycleResetTimer invalidate];
    }
    
    if (self.eventMonitor) {
        [NSEvent removeMonitor:self.eventMonitor];
        self.eventMonitor = nil;
    }
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

#pragma mark - Menu Bar Setup

- (void)setupMenuBar {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.button.title = @"📋";
     NSMenu *menu = [[NSMenu alloc] init];
     self.statusItem.menu = menu;
}

#pragma mark - Clipboard Monitoring

- (void)startClipboardMonitoring {
    self.clipboardTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                           target:self
                                                         selector:@selector(checkClipboard:)
                                                         userInfo:nil
                                                          repeats:YES];
    
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    self.lastChangeCount = [pasteboard changeCount];
}

- (void)checkClipboard:(NSTimer *)timer {
     NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
//    NSInteger currentChangeCount = self.clipboardHistory.count;
    NSString *copiedText = [pasteboard stringForType:NSPasteboardTypeString];
    NSString *last = self.clipboardHistory.lastObject;

//     if (currentChangeCount != self.lastChangeCount) {
    if (!last || ![copiedText isEqualToString:last]) {
//         self.lastChangeCount = currentChangeCount;
//         NSString *copiedText = [pasteboard stringForType:NSPasteboardTypeString];
         if (copiedText && [copiedText length] > 0) {
             self.currentHistoryIndex = 0;
             [self addToHistory:copiedText];
         }
     }
}

#pragma mark - History Management

- (void)addToHistory:(NSString *)text {
    if ([self.clipboardHistory containsObject:text]) {
        [self.clipboardHistory removeObject:text];
    }
    if (_clipboardHistory.count >= _maxHistorySize) {
//        for (NSInteger i = 0; i < self.clipboardHistory.count; i++) {
        for (NSInteger i = self.clipboardHistory.count - 1; i >= 0; i--) {
            if (![self.pinned containsObject:self.clipboardHistory[i]]) {
                [_clipboardHistory removeObjectAtIndex:i];
                return;
            }
        }
    }
//    [_clipboardHistory addObject:text];
    [_clipboardHistory insertObject:text atIndex:0];
    [self updateMenu];
}

- (void)updateMenu {
    if (!self.statusItem || !self.statusItem.menu) {
        return;
    }
    
    NSMenu *menu = self.statusItem.menu;
    [menu removeAllItems];
     for (NSInteger i = 0; i < self.clipboardHistory.count; i++) {
         NSString *text = self.clipboardHistory[i];
         NSString *preview = [text substringToIndex:MIN(50, text.length)];
         
         NSString *title = [self.pinned containsObject:text] ?
                           [NSString stringWithFormat:@"📌 %@", preview] :
                           preview;
         NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[title substringToIndex:MIN(50, title.length)]
                                                       action:@selector(copyHistoryItemToPasteboard:)
                                                keyEquivalent:@""];
         [item setTarget:self];
         item.tag = i;
         [item setAlternate:NO];
         item.keyEquivalentModifierMask = 0;
         
         [menu addItem:item];
         
         
         NSString *title2 = [self.pinned containsObject:text] ?  // Use 'text', not 'preview'
                           [NSString stringWithFormat:@"UNPIN: %@", preview] :
                           [NSString stringWithFormat:@"PIN: %@", preview];
//         NSMenuItem *deleteItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Delete: %@", preview]
//                                                             action:@selector(deleteHistoryItem:)
//                                                      keyEquivalent:@""];
         NSMenuItem *deleteItem = [[NSMenuItem alloc] initWithTitle:[title2 substringToIndex:MIN(50, title2.length)]
                                                             action:@selector(pinItem:)
                                                      keyEquivalent:@""];
         [deleteItem setTarget:self];
         deleteItem.tag = i;
         [deleteItem setAlternate:YES];
         deleteItem.keyEquivalentModifierMask = NSEventModifierFlagOption;
         [menu addItem:deleteItem];     }
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *permissionItem = [[NSMenuItem alloc] initWithTitle:@"Check Accessibility Permission"
                                                                action:@selector(checkAccessibilityPermission)
                                                         keyEquivalent:@""];
        [permissionItem setTarget:self];
        [menu addItem:permissionItem];
        
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"Clear"
                                                  action:@selector(clearClipboardHistory:)
                                           keyEquivalent:@""];
    [item setTarget:self];
    item.tag = self.clipboardHistory.count;
    [menu addItem:item];
    
    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit"
                                                      action:@selector(terminate:)
                                               keyEquivalent:@"q"];
    [menu addItem:quitItem];
}

#pragma mark - Actions

- (void)copyHistoryItemToPasteboard:(id)sender {
    NSMenuItem *menuItem = (NSMenuItem *)sender;
    NSInteger index = menuItem.tag;
        
    NSString *text = self.clipboardHistory[index];
     NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
     [pasteboard clearContents];
     [pasteboard setString:text forType:NSPasteboardTypeString];
     self.lastChangeCount = [pasteboard changeCount];
}

- (void)clearClipboardHistory:(id)sender {
//    self.clipboardHistory = [NSMutableArray array];
    for (NSInteger i = self.clipboardHistory.count-1; i >= 0; i--) {
        if (![self.pinned containsObject:self.clipboardHistory[i]]) {
            [_clipboardHistory removeObjectAtIndex:i];
        }
    }
    [self updateMenu];
}

- (void)deleteHistoryItem:(id)sender {
    NSButton *button = (NSButton *)sender;
    NSInteger index = button.tag;
    
    if (index >= 0 && index < self.clipboardHistory.count) {
        [self.clipboardHistory removeObjectAtIndex:index];
        [self updateMenu];
    }
}


- (void)pinItem:(id)sender {
    NSMenuItem *button = (NSMenuItem *)sender;
    NSInteger index = button.tag;
    
    if ([self.pinned containsObject:self.clipboardHistory[index]]) {
        [self.pinned removeObject:self.clipboardHistory[index]];
    } else if (self.pinned.count < self.maxHistorySize - 1) {
//        [self.pinned addObject:self.clipboardHistory[index]];
        [self.pinned insertObject:self.clipboardHistory[index] atIndex: 0];
    }
    [self updateMenu];
//    if (index >= 0 && index < self.clipboardHistory.count) {
//        [self.clipboardHistory removeObjectAtIndex:index];
//        [self updateMenu];
//    }
}

- (void)cycleToPreviousClipboard {
    if (self.clipboardHistory.count == 0) {
        return;
    }
    self.currentHistoryIndex = (self.currentHistoryIndex+1) % self.clipboardHistory.count;
    
    NSString *text = self.clipboardHistory[self.currentHistoryIndex];
    
    NSString *preview = [text substringToIndex:MIN(50, text.length)];
    if (text.length > 50) {
        preview = [preview stringByAppendingString:@"..."];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self showToast:preview];
    });
    
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString:text forType:NSPasteboardTypeString];
    self.lastChangeCount = [pasteboard changeCount];
    
    self.cycleResetTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                            target:self
                                                          selector:@selector(finalizeCycleSelection)
                                                          userInfo:nil
                                                           repeats:NO];
}

- (void)finalizeCycleSelection {
    NSString *text = self.clipboardHistory[self.currentHistoryIndex];
//    NSLog(@"%@", text);
//    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
//    [pasteboard clearContents];
//    [pasteboard setString:text forType:NSPasteboardTypeString];
//    self.lastChangeCount = [pasteboard changeCount];
    [self.clipboardHistory removeObject:text];
    [self.clipboardHistory insertObject:text atIndex:0];
    self.currentHistoryIndex = 0;
    [self updateMenu];
    self.cycleResetTimer = nil;
}

- (void)showToastCurrent {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSString *text = [pasteboard stringForType:NSPasteboardTypeString];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showToast:text];
    });
}

- (void)registerHotkey {
    if (self.eventMonitor) {
        return;
    }
    self.eventMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskKeyDown
                                          handler:^(NSEvent *event) {  // note: no return type, no return nil
        BOOL isCmd = (event.modifierFlags & NSEventModifierFlagCommand) != 0;
        BOOL isCtrl = (event.modifierFlags & NSEventModifierFlagControl) != 0;
        BOOL isVKey = event.keyCode == 9;
        BOOL isCKey = event.keyCode == 8;

        if (isCmd && isCtrl && isVKey) {
            [self cycleToPreviousClipboard];
        }
        if (isCmd && isCtrl && isCKey) {
            [self showToastCurrent];
        }
    }];
}

- (void)checkAccessibilityPermission {
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    BOOL trusted = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
    
    if (!trusted) {
        // Show user-friendly alert
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Accessibility Permission Required"];
            [alert setInformativeText:@"ClipboardManager needs Accessibility permission to detect the Cmd+Ctrl+V hotkey.\n\n1. Click 'Open System Settings'\n2. Find ClipboardManager in the list\n3. Toggle it ON\n4. Restart the app"];
            [alert addButtonWithTitle:@"Open System Settings"];
            [alert addButtonWithTitle:@"Cancel"];
            
            NSModalResponse response = [alert runModal];
            if (response == NSAlertFirstButtonReturn) {
                // Open System Settings to Accessibility pane
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"]];
            }
        });
    }
}

- (void)showToast:(NSString *)text {
    NSLog(@"showToast called with: %@", text);
    // Create HUD-style panel
    self.toastPanel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 300, 80)
                                                 styleMask:NSWindowStyleMaskBorderless | NSNonactivatingPanelMask
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
    self.toastPanel.becomesKeyOnlyIfNeeded = YES;
    self.toastPanel.floatingPanel = YES;
    NSPanel *toast = self.toastPanel;
    
    // HUD styling - dark, rounded, semi-transparent
    toast.backgroundColor = [NSColor colorWithWhite:0.1 alpha:0.85];
    toast.opaque = NO;
    toast.hasShadow = YES;
    toast.level = NSScreenSaverWindowLevel;
    toast.ignoresMouseEvents = YES;
    
    // Rounded corners
    toast.contentView.wantsLayer = YES;
    toast.contentView.layer.cornerRadius = 12.0;
    toast.contentView.layer.masksToBounds = YES;
    
    // Position in bottom-right corner
    NSRect screenFrame = [[NSScreen mainScreen] visibleFrame];
    CGFloat x = NSMaxX(screenFrame) - 320;  // 20px from right edge
    CGFloat y = NSMinY(screenFrame) + 20;    // 20px from bottom
    [toast setFrameOrigin:NSMakePoint(x, y)];
    
    // Title label
    NSTextField *titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 50, 260, 20)];
    titleLabel.stringValue = @"Clipboard";
    titleLabel.bezeled = NO;
    titleLabel.drawsBackground = NO;
    titleLabel.editable = NO;
    titleLabel.selectable = NO;
    titleLabel.textColor = [NSColor colorWithWhite:0.7 alpha:1.0];
    titleLabel.font = [NSFont systemFontOfSize:11];
    [toast.contentView addSubview:titleLabel];
    
    // Content label
    NSTextField *contentLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 15, 260, 30)];
    contentLabel.stringValue = text;
    contentLabel.bezeled = NO;
    contentLabel.drawsBackground = NO;
    contentLabel.editable = NO;
    contentLabel.selectable = NO;
    contentLabel.textColor = [NSColor whiteColor];
    contentLabel.font = [NSFont systemFontOfSize:14 weight:NSFontWeightMedium];
    [toast.contentView addSubview:contentLabel];
    
    // Fade in animation
    toast.alphaValue = 1.0;
    NSLog(@"Activation policy: %ld", [NSApp activationPolicy]);
    [toast setIsVisible:YES];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.2;
        toast.animator.alphaValue = 1.0;
    } completionHandler:^{
        // Auto-dismiss after 1.5 seconds
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                context.duration = 0.3;
                toast.animator.alphaValue = 0.0;
            } completionHandler:^{
                [toast close];
                self.toastPanel = nil;
            }];
        });
    }];
}

@end







