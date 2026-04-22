//
//  AppDelegate.m
//  ClipboardManager
//
//  Created by Riley Koo on 4/22/26.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.clipboardHistory = [NSMutableArray array];
    self.maxHistorySize = 20;
    self.lastChangeCount = 0;
    
    [self setupMenuBar];
    [self startClipboardMonitoring];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.clipboardTimer invalidate];
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
             [self addToHistory:copiedText];
         }
     }
}

#pragma mark - History Management

- (void)addToHistory:(NSString *)text {
    if (_clipboardHistory.count >= _maxHistorySize) {
        [_clipboardHistory removeObjectAtIndex:0];
    }
    [_clipboardHistory addObject:text];
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
    
         NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:preview
                                                       action:@selector(copyHistoryItemToPasteboard:)
                                                keyEquivalent:@""];
         [item setTarget:self];
         item.tag = i;
         [menu addItem:item];
     }
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    
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
    self.clipboardHistory = [NSMutableArray array];
}

@end
