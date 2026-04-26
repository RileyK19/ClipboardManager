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
    self.pinned = [NSMutableArray array];
    
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
    if ([self.clipboardHistory containsObject:text]) {
        [self.clipboardHistory removeObject:text];
    }
    if (_clipboardHistory.count >= _maxHistorySize) {
        for (NSInteger i = 0; i < self.clipboardHistory.count; i++) {
            if (![self.pinned containsObject:self.clipboardHistory[i]]) {
                [_clipboardHistory removeObjectAtIndex:i];
                return;
            }
        }
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
    for (NSInteger i = 0; i < self.clipboardHistory.count; i++) {
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
        [self.pinned addObject:self.clipboardHistory[index]];
    }
    [self updateMenu];
//    if (index >= 0 && index < self.clipboardHistory.count) {
//        [self.clipboardHistory removeObjectAtIndex:index];
//        [self updateMenu];
//    }
}

@end
